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
package org.eclipse.sprotty.util;

import java.util.Iterator;
import java.util.NoSuchElementException;

import org.eclipse.sprotty.SModelElement;

/**
 * An iterator that traverses a tree of model elements in depth-first order.
 */
public class SModelIterator implements Iterator<SModelElement> {
	
	private static class Entry {
		final SModelElement element;
		final int index;
		final Entry previous;
		
		Entry(SModelElement element, int index, Entry previous) {
			this.element = element;
			this.index = index;
			this.previous = previous;
		}
	}
	
	private Entry stack;
	
	public SModelIterator(SModelElement root) {
		if (root == null)
			throw new NullPointerException();
		stack = new Entry(root, -1, null);
	}
	
	@Override
	public boolean hasNext() {
		return stack != null;
	}

	@Override
	public SModelElement next() {
		if (stack == null)
			throw new NoSuchElementException();
		SModelElement element = stack.element;
		if (element.getChildren() != null && !element.getChildren().isEmpty()) {
			push(element, 0);
		} else {
			pop();
		}
		return element;
	}
	
	private void push(SModelElement element, int index) {
		Entry newEntry = new Entry(element.getChildren().get(index), index, stack);
		stack = newEntry;
	}
	
	private void pop() {
		Entry prevEntry = stack.previous;
		int nextIndex = stack.index + 1;
		stack = prevEntry;
		if (prevEntry != null) {
			SModelElement element = prevEntry.element;
			if (element.getChildren() != null && nextIndex < element.getChildren().size()) {
				push(element, nextIndex);
			} else {
				pop();
			}
		}
	}

}
