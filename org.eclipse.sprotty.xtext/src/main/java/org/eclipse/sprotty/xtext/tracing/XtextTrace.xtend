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

package org.eclipse.sprotty.xtext.tracing

import org.eclipse.emf.common.util.URI
import org.eclipse.lsp4j.Position
import org.eclipse.lsp4j.Range
import org.eclipse.xtend.lib.annotations.Data

import static extension java.lang.Integer.*
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor

@Data
@FinalFieldsConstructor
class XtextTrace {
	URI elementURI
	Range range
	
	override String toString() {
		val rangeQuery = '''«range.start.line»:«range.start.character»-«range.end.line»:«range.end.character»'''   
		return elementURI.appendQuery(rangeQuery).toString
	}
	
	new(String trace) {
		val uri = URI.createURI(trace)
		this.elementURI = uri.trimQuery
		val numbers = uri.query.split('[:-]').map[parseInt]
		this.range = new Range(new Position(numbers.get(0), numbers.get(1)), new Position(numbers.get(2), numbers.get(3)))
	}
}



