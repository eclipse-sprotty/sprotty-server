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
 
package org.eclipse.sprotty.xtext

import com.google.inject.Inject
import org.eclipse.emf.ecore.EObject
import org.eclipse.sprotty.HtmlRoot
import org.eclipse.sprotty.IDiagramServer
import org.eclipse.sprotty.IPopupModelFactory
import org.eclipse.sprotty.PreRenderedElement
import org.eclipse.sprotty.RequestPopupModelAction
import org.eclipse.sprotty.SIssueMarker
import org.eclipse.sprotty.SModelElement
import org.eclipse.sprotty.xtext.ILanguageAwareDiagramServer
import org.eclipse.sprotty.xtext.tracing.ITraceProvider
import org.eclipse.xtext.documentation.IEObjectDocumentationProvider
import org.eclipse.xtext.naming.IQualifiedNameConverter
import org.eclipse.xtext.naming.IQualifiedNameProvider

/**
 * Provides pop-ups with issues, the qualified name and type, and the docs from a
 * {@link SModelElement} that traces back to an Xtext model element.  
 * 
 * Uses fontawesome for the icons representing the issues' severities.
 */
class PopupModelFactory implements IPopupModelFactory {

	@Inject extension ITraceProvider
	@Inject extension IEObjectDocumentationProvider
	@Inject extension IQualifiedNameProvider
	@Inject IQualifiedNameConverter qualifiedNameConverter
	
	override createPopupModel(SModelElement element, RequestPopupModelAction request, IDiagramServer server) {
		switch element {
			SIssueMarker: {
				val popupId = element.id + '-popup'
				new HtmlRoot [
					id = popupId
					children = #[
						new PreRenderedElement [
							id = popupId + '-body'
							code = '''«getIssueRow(element)»'''
						]
					]
					canvasBounds = request.bounds
				]
			}
			case null:
				null 
 			default: {
				val future = element.withSource(server as ILanguageAwareDiagramServer) [ semanticElement, context |
					semanticElement?.createPopup(element, request) ?: null
				]
				future.get
			} 
		}
	}
	
	protected def CharSequence getIssueRow(SIssueMarker element) '''
		<div class="sprotty-infoBlock">
			<div class="sprotty-infoRow">
				«FOR issue: element.issues»
					<div class="sprotty-infoText">
						<i class="fa «issue.severity.iconClass» sprotty-«issue.severity»" />«issue.message»
					</div>
				«ENDFOR»
			</div>
		</div>
	'''
	
	
	protected def getIconClass(String severity) {
		switch severity {
			case 'error', 
			case 'warning': 'fa-exclamation-circle'
			case 'info': 'fa-info-circle'
		}
	}

	protected def createPopup(EObject semanticElement, SModelElement element, RequestPopupModelAction request) {
		val popupId = element.id + '-popup'
		val title = getTitle(semanticElement)
		val issueMarker = element.children?.filter(SIssueMarker)?.head
		val docs = semanticElement.documentation
		if (title === null && issueMarker === null && docs === null)
			return null
		new HtmlRoot [
			id = popupId
			children = #[
				new PreRenderedElement [
					id = popupId + '-body'
					code = '''
						<div class="sprotty-infoBlock">
							«IF issueMarker !== null»
								«getIssueRow(issueMarker)»
							«ENDIF»
							«IF title !== null»
								<div class="sprotty-infoRow">
									<div class="sprotty-infoTitle">«title»</div>
								</div>
							«ENDIF»
							«IF docs !== null»
								<div class="sprotty-infoRow">
									<div class="sprotty-infoText">«docs»</div>
								</div>
							«ENDIF»
						</div>
					'''
				]
			]
			canvasBounds = request.bounds
		]
	}
	
	protected def String getTitle(EObject semanticElement) {
		getDisplayName(semanticElement) + ' (' + semanticElement.eClass.name + ')'
	}
	
	protected def String getDisplayName(EObject semanticElement) {
		val qualifiedName = semanticElement.fullyQualifiedName
		if (qualifiedName !== null)
			qualifiedNameConverter.toString(qualifiedName) 
		else 
		 	'<unnamed>'
	}
}