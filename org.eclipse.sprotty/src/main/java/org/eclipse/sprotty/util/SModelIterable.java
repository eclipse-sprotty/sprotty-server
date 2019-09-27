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

import java.util.stream.Stream;
import java.util.stream.StreamSupport;

import org.eclipse.sprotty.SModelElement;

/**
 * An iterable that traverses a tree of model elements in depth-first order
 * using an {@link SModelIterator}.
 */
public class SModelIterable implements Iterable<SModelElement> {
	
	private final SModelElement element;
	
	public SModelIterable(SModelElement element) {
		this.element = element;
	}

	@Override
	public SModelIterator iterator() {
		return new SModelIterator(element);
	}
	
	public Stream<SModelElement> stream() {
		return StreamSupport.stream(spliterator(), false);
	}
	
}