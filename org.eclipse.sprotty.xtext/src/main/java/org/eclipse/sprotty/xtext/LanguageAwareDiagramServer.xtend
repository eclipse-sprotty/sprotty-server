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
import org.apache.log4j.Logger
import org.eclipse.emf.ecore.EObject
import org.eclipse.sprotty.DefaultDiagramServer
import org.eclipse.sprotty.DiagramOptions
import org.eclipse.sprotty.IDiagramServer
import org.eclipse.sprotty.RequestModelAction
import org.eclipse.sprotty.SModelRoot
import org.eclipse.sprotty.ServerStatus
import org.eclipse.sprotty.util.IdCache
import org.eclipse.sprotty.xtext.ls.DiagramLanguageServer
import org.eclipse.sprotty.xtext.ls.DiagramUpdater
import org.eclipse.sprotty.xtext.ls.IssueProvider
import org.eclipse.xtend.lib.annotations.Accessors
import org.eclipse.xtext.diagnostics.Diagnostic
import org.eclipse.xtext.diagnostics.Severity
import org.eclipse.xtext.ide.server.ILanguageServerAccess
import org.eclipse.xtext.ide.server.ILanguageServerAccess.Context

import static org.eclipse.sprotty.ServerStatus.Severity.*

/**
 * Diagram server for Xtext languages. When a {@link RequestModelAction} is received,
 * a diagram is generated for the corresponding resource by calling
 * {@link DiagramUpdater#updateDiagram(LanguageAwareDiagramServer)}.
 */
class LanguageAwareDiagramServer extends DefaultDiagramServer implements ILanguageAwareDiagramServer {
	
	static val LOG = Logger.getLogger(LanguageAwareDiagramServer)
	
	@Accessors
	DiagramLanguageServer diagramLanguageServer
	
	@Accessors 
	String diagramType
	
	@Inject com.google.inject.Provider<IDiagramGenerator> diagramGeneratorProvider
	
	override protected handle(RequestModelAction request) {
		if (model.type == 'NONE' && diagramLanguageServer !== null) {
			if (!request.requestId.nullOrEmpty)
				LOG.warn("Model requests are not supported by the Xtext diagram server.")
			copyOptions(request)
			diagramLanguageServer.diagramUpdater.updateDiagram(this)
		} else {
			super.handle(request)
		}
	}
	
	override getSourceUri() {
		options.get(DiagramOptions.OPTION_SOURCE_URI)
	}
	
	override SModelRoot generate(ILanguageServerAccess.Context context, IssueProvider issueProvider) {
		val status = getServerStatus(context, issueProvider)
		setStatus(status)
		val root = if (shouldGenerate(status)) {
			try {
				val generatorContext = createDiagramGeneratorContext(context, this, issueProvider)
				val diagramGenerator = diagramGeneratorProvider.get
				diagramGenerator.generate(generatorContext)
			} catch (Exception exc) {
				setStatus(new ServerStatus(FATAL, 'Error generating diagram. See language server log for details.'))
				LOG.error('''Error generating diagram for «context.resource.URI»:''',exc)
				null			
			}
		} else {
			null
		}
		root
	}

	protected def ServerStatus getServerStatus(ILanguageServerAccess.Context context, IssueProvider issueProvider) {
		if (context.resource === null)
			return new ServerStatus(FATAL, 'Cannot update diagram: Model does not exist')
		if (issueProvider.exists[
			severity === Severity.ERROR 
				&& (code == Diagnostic.LINKING_DIAGNOSTIC 
				|| code == Diagnostic.SYNTAX_DIAGNOSTIC
				|| code == Diagnostic.SYNTAX_DIAGNOSTIC_WITH_RANGE)]) 
			return new ServerStatus(FATAL, 'Cannot update diagram: Model has syntax/linking errors')
		val maxSeverity = issueProvider.maxSeverity
		switch maxSeverity {
			case Severity.ERROR:
				return new ServerStatus(ERROR, 'Model has validation errors')
			case Severity.WARNING: 
				return new ServerStatus(WARNING, 'Model has warnings')
			default:
				return ServerStatus.OK
		}
	}
	
	protected def shouldGenerate(ServerStatus status) {
		return status.severity !== FATAL
	}
	
	protected def createDiagramGeneratorContext(Context context, IDiagramServer server, IssueProvider issueProvider) {
		new IDiagramGenerator.Context(context.resource, server.diagramState, new IdCache<EObject>(), issueProvider, context.cancelChecker)
	}
}