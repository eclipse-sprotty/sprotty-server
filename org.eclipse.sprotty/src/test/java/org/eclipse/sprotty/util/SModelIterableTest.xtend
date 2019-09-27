/********************************************************************************
 * Copyright (c) 2019 TypeFox and others.
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

import java.util.stream.Collectors
import org.eclipse.sprotty.SNode
import org.junit.Test

import static org.junit.Assert.*

class SModelIterableTest {
	
	@Test
	def void testIterateTree() {
		val tree = createBinaryTree(10, 'n')
		assertEquals(
			#['n', 'n0', 'n00', 'n000', 'n01', 'n010', 'n1', 'n10', 'n100', 'n11'],
			new SModelIterable(tree).map[id].toList
		)
	}
	
	@Test
	def void testIterateSubTree() {
		val tree = createBinaryTree(10, 'n')
		val subtree = tree.children.get(0).children.get(1)
		assertEquals(
			#['n01', 'n010'],
			new SModelIterable(subtree).map[id].toList
		)
	}
	
	@Test
	def void testStreamTree() {
		val tree = createBinaryTree(10, 'n')
		assertEquals(
			#['n', 'n0', 'n00', 'n000', 'n01', 'n010', 'n1', 'n10', 'n100', 'n11'],
			new SModelIterable(tree).stream.map[id].collect(Collectors.toList)
		)
	}
	
	private def SNode createBinaryTree(int size, String name) {
		new SNode [
			type = 'node'
			id = name
			val rightSize = (size - 1) / 2
			val leftSize = size - rightSize - 1
			if (leftSize > 0 && rightSize > 0) {
				children = #[
					createBinaryTree(leftSize, name + 0),
					createBinaryTree(rightSize, name + 1)
				]
			} else if (leftSize > 0) {
				children = #[
					createBinaryTree(leftSize, name + 0)
				]
			}
		]
	}
	
}