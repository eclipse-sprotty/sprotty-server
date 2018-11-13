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

import java.util.ArrayList
import org.eclipse.emf.ecore.EObject
import org.eclipse.sprotty.SModelElement
import org.eclipse.sprotty.SIssue
import static org.eclipse.sprotty.SIssue.Severity.*
import org.eclipse.sprotty.SIssueMarker
import org.eclipse.xtext.diagnostics.Severity

class SIssueMarkerDecorator {
	
	def <T extends SModelElement> T addIssueMarkers(T sElement, EObject element, extension IDiagramGenerator.Context context) {
		val xtextIssues = context.issueProvider.getIssues(element)
		if (!xtextIssues.empty) {
			val marker = new SIssueMarker [
				issues = xtextIssues.sortBy[severity.ordinal].map[ xtextIssue |
					new SIssue => [
						message = xtextIssue.message
						severity = xtextIssue.severity.convert
					]
				].toList
				id = idCache.uniqueId(idCache.getId(element) + '.marker')
			]
			val newChildren = if (sElement.children !== null) 
					new ArrayList(sElement.children)
				else
					newArrayList
			newChildren += marker
			sElement.children = newChildren
		}	
		sElement
	}
	
	protected def SIssue.Severity convert(Severity xtextSeverity) {
		switch xtextSeverity {
			case ERROR: error
			case WARNING: warning
			default: info
		}
	}
}