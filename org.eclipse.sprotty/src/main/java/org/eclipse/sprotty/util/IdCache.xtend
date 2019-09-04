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
import org.apache.log4j.Logger

/** 
 * Assert unique IDs for model elements and and allow to look them up.
 * 
 * In Sprotty, it's the diagram implementor's responsibility to create unique 
 * IDs for SModel elements. For consistent animations on model updates, these
 * IDs should be based on properties of the underlying model in a way that 
 * they are resilient to reordering and if possible renaming.
 * 
 * This class makes sure these IDs are unique, and allows to look them up for 
 * a given model element in order to establish cross references in the SModel, 
 * e.g. for <code>sourceId</code> and <code>target</code> of an <code>SEdge</code>. 
 * 
 * @param T the type of the underling model element
 */
class IdCache <T> {
	
	static val LOG = Logger.getLogger(IdCache) 
	
	val BiMap<String, T> id2element = HashBiMap.create
	val Set<String> otherIds = newHashSet

	def String uniqueId(T element, String idProposal) {
		createUniqueId(element, idProposal)
	}

	def String uniqueId(String idProposal) {
		createUniqueId(null, idProposal)
	}

	def boolean isIdAlreadyUsed(String id) {
		id2element.containsKey(id) || otherIds.contains(id)
	}

	protected def String createUniqueId(T element, String idPrefix) {
		var String proposedId = idPrefix
		var count = 0
		do {
			proposedId = idPrefix + if (count === 0) '' else count
			if (element !== null && id2element.get(proposedId) == element)
				return proposedId
			count++ 
		} while (proposedId.idAlreadyUsed)
		if (count > 1)
			LOG.error('''Duplicate ID '«idPrefix»'. Using «proposedId» instead''')
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
