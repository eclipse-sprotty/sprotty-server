/********************************************************************************
 * Copyright (c) 2017-2018 TypeFox and others.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v. 2.0 which is available at
 * http://www.eclipse.org/legal/epl-2.0.
 *
 * This Source Code may also be made available under the following Secondary
 * Licenses when the conditions for such availability set forth in the Eclipse
 * Public License v. 2.0 are satisfied: GNU General Public License, version 2
 * with the GNU Classpath Exception which is available at
 * https://www.gnu.org/software/classpath/license.html.
 *
 * SPDX-License-Identifier: EPL-2.0 OR GPL-2.0 WITH Classpath-exception-2.0
 ********************************************************************************/
package org.eclipse.sprotty.xtext

import com.google.inject.Inject
import com.google.inject.Provider
import java.util.Collection
import java.util.List
import java.util.Map
import java.util.concurrent.CompletableFuture
import org.apache.log4j.Logger
import org.eclipse.emf.common.util.URI
import org.eclipse.lsp4j.jsonrpc.Endpoint
import org.eclipse.lsp4j.jsonrpc.services.ServiceEndpoints
import org.eclipse.sprotty.ActionMessage
import org.eclipse.sprotty.IDiagramServer
import org.eclipse.sprotty.ServerStatus
import org.eclipse.xtend.lib.annotations.Accessors
import org.eclipse.xtext.diagnostics.Diagnostic
import org.eclipse.xtext.diagnostics.Severity
import org.eclipse.xtext.ide.server.ILanguageServerAccess
import org.eclipse.xtext.ide.server.ILanguageServerExtension
import org.eclipse.xtext.ide.server.UriExtensions
import org.eclipse.xtext.validation.CheckMode
import org.eclipse.xtext.validation.IResourceValidator
import org.eclipse.xtext.validation.Issue

import static org.eclipse.sprotty.ServerStatus.Severity.*
import org.eclipse.xtext.ide.server.ILanguageServerAccess.Context
import org.eclipse.sprotty.util.IdCache
import org.eclipse.emf.ecore.EObject

/**
 * An extension of the <a href="https://github.com/Microsoft/language-server-protocol">Language Server Protocol (LSP)</a>
 * that adds diagram-related messages.
 */
class DiagramLanguageServerExtension implements DiagramServerEndpoint, ILanguageServerExtension, IDiagramServer.Provider {
	
	protected static val LOG = Logger.getLogger(DiagramLanguageServerExtension)
	
	@Inject extension IResourceValidator

	@Inject extension UriExtensions
	
	@Inject Provider<IDiagramServer> diagramServerProvider
	
	@Inject Provider<IDiagramGenerator> diagramGeneratorProvider
	
	DeferredDiagramUpdater updater

	@Accessors(PROTECTED_GETTER)
	val Map<String, IDiagramServer> diagramServers = newLinkedHashMap

	DiagramEndpoint _client

	protected extension ILanguageServerAccess languageServerAccess
	
	override initialize(ILanguageServerAccess access) {
		this.languageServerAccess = access
		updater = new DeferredDiagramUpdater([it | doUpdateDiagrams(it)])
		access.addBuildListener [ deltas |
			updateDiagrams(deltas.map[uri].toSet)
		]
	}
	def ILanguageServerAccess getLanguageServerAccess() {
		languageServerAccess
	}

	protected def DiagramEndpoint getClient() {
		if (_client === null) {
			val client = languageServerAccess.languageClient
			if (client instanceof Endpoint) {
				_client = ServiceEndpoints.toServiceObject(client, DiagramEndpoint)
			}
		}
		return _client
	}
	
	/**
	 * Return the diagram server with the given client identifier, or create one if it does not
	 * exist yet.
	 */
	override getDiagramServer(String clientId) {
		synchronized (diagramServers) {
			var server = diagramServers.get(clientId)
			if (server === null) {
				server = diagramServerProvider.get
				server.clientId = clientId
				initializeDiagramServer(server)
				diagramServers.put(clientId, server)
			}
			return server
		}
	}
	
	/**
	 * Initialize a diagram server. Override this in order to use custom settings for diagram servers.
	 */
	protected def void initializeDiagramServer(IDiagramServer server) {
		server.remoteEndpoint = [ message |
			client?.accept(message)
		]
		if (server instanceof LanguageAwareDiagramServer)
			server.languageServerExtension = this
	}
	
	def List<? extends ILanguageAwareDiagramServer> findDiagramServersByUri(String uri) {
		synchronized (diagramServers) {
			diagramServers.values.filter(ILanguageAwareDiagramServer).filter[sourceUri == uri].toList
		}
	}
	
	/**
	 * Find a diagram server for the client referred in the given message and forward the message to
	 * that server.
	 */
	override void accept(ActionMessage message) {
		val server = getDiagramServer(message.clientId)
		server.accept(message)
	}
	
	/**
	 * Remove the diagram server associated with the given client identifier.
	 */
	override didClose(String clientId) {
		synchronized (diagramServers) {
			diagramServers.remove(clientId)
		}
	}
	
	/**
	 * Update the diagrams for the given URIs using the configured diagram generator.
	 */
	def void updateDiagrams(Collection<? extends URI> uris) {
		updater.updateLater(uris)
	}

	protected def doUpdateDiagrams(Collection<? extends URI> uris) {
		for (uri : uris) {
			val path = uri.toUriString
			val diagramServers = findDiagramServersByUri(path)
			doUpdateDiagrams(path, diagramServers)
		}		
	} 

	/**
	 * Update the diagram for the given diagram server using the configured diagram generator.
	 */
	def void updateDiagram(LanguageAwareDiagramServer diagramServer) {
		val path = diagramServer.sourceUri
		if (path !== null) 
			doUpdateDiagrams(path, #[diagramServer])
	}

	protected def CompletableFuture<Void> doUpdateDiagrams(String path, List<? extends ILanguageAwareDiagramServer> diagramServers) {
		if (diagramServers.empty) {
			return CompletableFuture.completedFuture(null)
		}
		return path.doRead [ context |
			val issues = context.resource?.validate(CheckMode.NORMAL_AND_FAST, context.cancelChecker)
			val status = getServerStatus(issues)
			val issueProvider = new IssueProvider(issues ?: emptyList) 
			return diagramServers.map [ server |
				server -> {
					server.status = status
					if (shouldGenerate(status)) {
						val generatorContext = createDiagramGeneratorContext(context, server, issueProvider)
						val diagramGenerator = diagramGeneratorProvider.get
						diagramGenerator.generate(generatorContext)
					} else {
						null
					}
				}
			]
		].thenAccept [ resultList |
			resultList.filter[value !== null].forEach[key.updateModel(value)]
		].exceptionally [ throwable |
			LOG.error('Error while processing build results', throwable)
			return null
		]
	}

	protected def ServerStatus getServerStatus(List<Issue> issues) {
		if (issues === null)
			return new ServerStatus(FATAL, 'Cannot update diagram: Model does not exist')
		if (issues.exists[
			severity === Severity.ERROR 
				&& (code == Diagnostic.LINKING_DIAGNOSTIC 
				|| code == Diagnostic.SYNTAX_DIAGNOSTIC
				|| code == Diagnostic.SYNTAX_DIAGNOSTIC_WITH_RANGE)
			])
			return new ServerStatus(FATAL, 'Cannot update diagram: Model has syntax/linking errors')
		if (issues.exists[severity === Severity.ERROR])
			return new ServerStatus(ERROR, 'Model has validation errors')
		if (issues.exists[severity === Severity.WARNING]) 
			return new ServerStatus(WARNING, 'Model has warnings')
		return ServerStatus.OK
	}
	
	protected def shouldGenerate(ServerStatus status) {
		return status.severity !== FATAL
	}
	
	protected def createDiagramGeneratorContext(Context context, IDiagramServer server, IssueProvider issueProvider) {
		new IDiagramGenerator.Context(context.resource, server.diagramState, new IdCache<EObject>(), issueProvider, context.cancelChecker)
	}
}