package org.eclipse.sprotty.xtext.ide

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

class IdePopupModelFactory implements IPopupModelFactory {

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
 			SModelElement: {
				val future = element.withSource(server as ILanguageAwareDiagramServer) [ semanticElement, context |
					createPopup(semanticElement, element, request)
				]
				future.get
			} 
			default: null
		}
	}
	
	protected def CharSequence getIssueRow(SIssueMarker element) '''
		<div class="infoBlock">
			<div class="sprotty-infoRow">
				«FOR issue: element.issues»
					<div class="sprotty-infoText">
						<i class="fa «issue.severity.fontawesomeIconClass» sprotty-«issue.severity»" />«issue.message»
					</div>
				«ENDFOR»
			</div>
		</div>
	'''
	
	
	protected def getFontawesomeIconClass(String severity) {
		switch severity {
			case 'error', 
			case 'warning': 'fa-exclamation-circle'
			case 'info': 'fa-info-circle'
		}
		
	}

	protected def createPopup(EObject semanticElement, SModelElement element, RequestPopupModelAction request) {
		val popupId = element.id + '-popup'
		val title = getTitle(semanticElement)
		val issueMarker = element.children.filter(SIssueMarker).head
		val docs = semanticElement.documentation
		if (title === null && issueMarker === null && docs === null)
			return null
		new HtmlRoot [
			id = popupId
			children = #[
				new PreRenderedElement [
					id = popupId + '-body'
					code = '''
						<div class="infoBlock">
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
		qualifiedNameConverter.toString(semanticElement.fullyQualifiedName) + ' (' + semanticElement.eClass.name + ')'
	}
	
}