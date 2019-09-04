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

package org.eclipse.sprotty.util

import com.google.common.collect.BiMap
import com.google.common.collect.HashBiMap
import java.util.Set
import org.eclipse.sprotty.SModelElement

/** 
 * Helps to create unique IDs for {@link SModelElement}s.
 */
class IdCache <T> {
	
	val BiMap<String, T> id2element = HashBiMap.create
	val Set<String> otherIds = newHashSet

	def String uniqueId(T element, String idProposal) {
		uniqueId(element, idProposal, 0)
	}

	def String uniqueId(String idProposal) {
		uniqueId(null, idProposal, 0)
	}

	def String uniqueId(T element, String idPrefix, int countStart) {
		var String proposedId
		var count = countStart
		do {
			proposedId = if (count == 0) idPrefix else idPrefix + count
			if (element !== null && id2element.get(proposedId) == element)
				return proposedId
			count++
		} while (id2element.containsKey(proposedId) || otherIds.contains(proposedId))
		
		if (element === null) {
			otherIds.add(proposedId)
		} else {
			id2element.put(proposedId, element)
		}
		return proposedId
	}

	def getId(T element) {
		id2element.inverse.get(element)
	}

}
