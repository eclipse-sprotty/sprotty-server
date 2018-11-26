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

import com.google.common.collect.Multimap
import com.google.common.collect.Multimaps
import java.util.List
import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.EObject
import org.eclipse.xtext.diagnostics.Diagnostic
import org.eclipse.xtext.diagnostics.Severity
import org.eclipse.xtext.validation.Issue

import static extension org.eclipse.emf.ecore.util.EcoreUtil.*

/**
 * Efficiently provides issues per model element.
 */
class IssueProvider {
	val Multimap<URI, Issue> map

	new(List<Issue> issues) {
		map = Multimaps.index(issues.filter[uriToProblem !== null], [uriToProblem])
	}

	def Iterable<? extends Issue>getIssues(EObject element) {
		map.get(element.URI)
	}
	
	def Severity getMaxSeverity() {
		if (hasIssues) 
			map.values.map[severity].minBy[ordinal]
		else
			null 
	}
	
	def hasLinkingOrSyntaxErrors() {
		map.values.exists[
			severity === Severity.ERROR 
				&& (code == Diagnostic.LINKING_DIAGNOSTIC 
				|| code == Diagnostic.SYNTAX_DIAGNOSTIC
				|| code == Diagnostic.SYNTAX_DIAGNOSTIC_WITH_RANGE)
		]
	}
	
	def boolean hasIssues() {
		!map.empty
	}
	
	def exists((Issue)=>boolean predicate) {
		map.values.exists(predicate)
	}
}
