/********************************************************************************
 * Copyright (c) 2018 TypeFox and others.
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

package org.eclipse.sprotty.xtext.ls

import com.google.inject.Inject
import com.google.inject.Singleton
import org.eclipse.emf.common.util.URI
import org.eclipse.lsp4j.DocumentHighlightParams
import org.eclipse.lsp4j.InitializeParams
import org.eclipse.lsp4j.VersionedTextDocumentIdentifier
import org.eclipse.lsp4j.jsonrpc.Endpoint
import org.eclipse.lsp4j.jsonrpc.services.ServiceEndpoints
import org.eclipse.sprotty.ActionMessage
import org.eclipse.sprotty.DiagramOptions
import org.eclipse.sprotty.IDiagramServer
import org.eclipse.sprotty.RequestModelAction
import org.eclipse.sprotty.xtext.DiagramHighlightService
import org.eclipse.sprotty.xtext.IDiagramServerFactory
import org.eclipse.xtend.lib.annotations.Accessors
import org.eclipse.xtext.ide.server.LanguageServerImpl
import org.eclipse.xtext.ide.server.UriExtensions
import org.eclipse.xtext.util.internal.Log

/**
 * An extended language server that adds diagram-related messages to the
 * <a href="https://github.com/Microsoft/language-server-protocol">Language Server Protocol (LSP)</a>.
 * 
 * This class is instantiated by the ServerModule's container, i.e. it is independent of 
 * the languages and diagram types in the language server. 
 * 
 * It uses {@link IDiagramServerFactory}s to instantiate language and diagramType specific 
 * {@link IDiagramServer}s, a {@link IDiagramServerManager} to manage these instances and
 * a {@link DiagramUpdater} to sync the diagram with model changes.
 */
@Log
@Singleton
class DiagramLanguageServer extends LanguageServerImpl implements DiagramServerEndpoint {
	
	@Inject extension UriExtensions
	
	@Inject
	@Accessors(PUBLIC_GETTER)
	IDiagramServerManager diagramServerManager

	@Inject
	@Accessors(PUBLIC_GETTER)
	DiagramUpdater diagramUpdater
	
	protected DiagramEndpoint _client 
	
	override initialize(InitializeParams params) {
		super.initialize(params).thenApply[ result |
			diagramUpdater.initialize(this)
			diagramServerManager.initialize(this)
			result
		]
	}
	
	override didClose(String clientId) {
		diagramServerManager.removeDiagramServer(clientId)
	}
	
	override accept(ActionMessage actionMessage) {
		val diagramType = if (actionMessage.action instanceof RequestModelAction) 
				(actionMessage.action as RequestModelAction).options.get(DiagramOptions.OPTION_DIAGRAM_TYPE)
			else 
			 	null
		diagramServerManager
			.getDiagramServer(diagramType, actionMessage.clientId)
			?.accept(actionMessage)
	}
	
	def DiagramEndpoint getClient() {
		if (_client === null) {
			val client = languageServerAccess.languageClient
			if (client instanceof Endpoint) {
				_client = ServiceEndpoints.toServiceObject(client, clientInterface)
			}
		}
		return _client
	}
	
	protected def Class<? extends DiagramEndpoint> getClientInterface() {
		DiagramEndpoint
	}
	
	
	
	override getLanguageServerAccess() {
		super.languageServerAccess
	}
	
	/**
	 * Use documentHighlight to select element under cursor in the diagram.
	 */
	override documentHighlight(DocumentHighlightParams params) {
		val result = super.documentHighlight(params)
		val URI uri = params.textDocument.uri.toUri
		workspaceManager.doRead(uri) [ doc, resource |
			if (params.textDocument instanceof VersionedTextDocumentIdentifier) {
				val version = (params.textDocument as VersionedTextDocumentIdentifier).version
				if (version !== null && version !== doc.version)
					return null
			}
			try {
				val diagramHighlightService = languagesRegistry
					.getResourceServiceProvider(uri)
					.get(DiagramHighlightService)
				if (diagramHighlightService !== null) {
					val offset = doc.getOffSet(params.position)
					diagramServerManager.findDiagramServersByUri(uri.toString).forEach [ server |
						diagramHighlightService.selectElementFor(server, resource, offset)
					]
				}
			} catch (Exception exc) {
				LOG.warn('Highlighting diagram element failed', exc)
			}
			null
		]
		result
	}
}

