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

import java.util.Map
import java.util.Set
import org.eclipse.sprotty.SModelElement
import org.apache.log4j.Logger

/** 
 * Helps to create unique IDs for {@link SModelElement}s.
 */
class IdCache <T> {
	
	static val LOG = Logger.getLogger(IdCache)

	Map<T, String> element2id = newHashMap
	Map<String, T> id2element = newHashMap
	Set<String> otherIds = newHashSet

	def String uniqueId(T element, String idProposal) {
		uniqueId(element, idProposal, 0)
	}

	def String uniqueId(String idProposal) {
		uniqueId(null, idProposal, 0)
	}

	protected def String uniqueId(T element, String idPrefix, int count) {
		val proposedId = if (count === 0)
				idPrefix
			else
				idPrefix + count

		val existingElement = id2element.get(proposedId)
		if (existingElement !== null) {
			if (existingElement == element)
				return proposedId
			else
				handleDuplicate(element, idPrefix, count)

		}
		if (otherIds.contains(proposedId))
			handleDuplicate(element, idPrefix, count)

		if (element === null) {
			otherIds.add(proposedId)
		} else {
			element2id.put(element, proposedId)
			id2element.put(proposedId, element)
		}
		return proposedId
	}

	def getId(T element) {
		element2id.get(element)
	}

	protected def String handleDuplicate(T element, String duplicateId, int count) {
		LOG.warn('''Duplicate ID '«duplicateId»«if (count > 0) count else ''»'«»''')
		return uniqueId(element, duplicateId, count + 1)
	}
}
