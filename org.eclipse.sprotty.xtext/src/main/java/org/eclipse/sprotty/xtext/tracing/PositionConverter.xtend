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

import org.eclipse.emf.ecore.EObject
import org.eclipse.lsp4j.Position
import org.eclipse.xtext.resource.XtextResource
import org.eclipse.lsp4j.Range
import org.eclipse.xtext.util.ITextRegion

class PositionConverter {
	
	def toPosition(int offset, EObject context) {
		val resource = context.eResource
		if(resource instanceof XtextResource) {
			val contents = resource.parseResult.rootNode.text
	        val l = contents.length
	        if (offset < 0 || offset > l)
	            throw new IndexOutOfBoundsException("Offset: " + offset)
	        val char NL = '\n'
	        var line = 0
	        var column = 0
	        for (var i = 0; i < l; i++) {
	            val ch = contents.charAt(i)
	            if (i === offset) {
	                return new Position(line, column)
	            }
	            if (ch === NL) {
	                line++
	                column = 0
	            } else {
	                column++
	            }
	        }
	        return new Position(line, column)
		}
		throw new IllegalArgumentException(resource?.class?.simpleName + ' is not an XtextResource');
	}
	
	def toRange(ITextRegion region, EObject context) {
		toRange(region.offset, region.length, context)
	}
	
	def toRange(int offset, int length, EObject context) {
		val start = toPosition(offset, context)
		val end = toPosition(offset + length, context)
		return new Range(start, end)	
	}
}
