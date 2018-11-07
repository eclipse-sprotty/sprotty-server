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

import java.util.Map
import org.eclipse.emf.ecore.EObject
import org.eclipse.xtext.util.internal.Log
import java.util.Set

@Log
class IdCache {
	
	Map<EObject, String> element2id = newHashMap
	Map<String, EObject> id2element = newHashMap
	Set<String> otherIds = newHashSet
	
	def String uniqueId(EObject element, String idProposal) {
		uniqueId(element, idProposal, 0)
	}

	def String uniqueId(String idProposal) {
		uniqueId(null, idProposal, 0)
	}

	protected def String uniqueId(EObject element, String idPrefix, int count) {
		val proposedId = if(count === 0)
				idPrefix
			else
				idPrefix + count
				
		val existingElement = id2element.get(proposedId)
		if (existingElement !== null) {
			if (existingElement == element) {
				return proposedId
			} else {
				LOG.warn('''Duplicate ID '«proposedId»'«»''')
				return uniqueId(element, proposedId, count + 1)
			}  
		} 
		if (otherIds.contains(proposedId)) {
			LOG.warn('''Duplicate ID '«proposedId»'«»''')
			return uniqueId(element, proposedId, count + 1)
		} 
		
		if(element === null) { 
			otherIds.add(proposedId)
		} else {
			element2id.put(element, proposedId)
			id2element.put(proposedId, element)
		}
		return proposedId 
	}

	def getId(EObject element) {
		element2id.get(element)
	}
}