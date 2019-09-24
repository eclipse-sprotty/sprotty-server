/********************************************************************************
 * Copyright (c) 2017-2019 TypeFox and others.
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
package org.eclipse.sprotty;

import org.apache.log4j.Logger;

/**
 * Copies bounds from a <code>ComputedBoundsAction</code> to the given <code>root</code>
 */
public class ComputedBoundsApplicator {
	
	private static final Logger LOG = Logger.getLogger(ComputedBoundsAction.class);
	
	/**
	 * Apply the computed bounds from the given action to the model.
	 */
	public void applyBounds(SModelRoot root, ComputedBoundsAction action) {
		SModelIndex index = new SModelIndex(root);
		for (ElementAndBounds b : action.getBounds()) {
			SModelElement element = index.get(b.getElementId());
			if (element instanceof BoundsAware) {
				BoundsAware bae = (BoundsAware) element;
				if (b.getNewPosition() != null)
					bae.setPosition(new Point(b.getNewPosition().getX(), b.getNewPosition().getY()));
				if (b.getNewSize() == null)
					LOG.error("ElementAndBounds#newSize is null. Make sure you are using a current version of sprotty on the client");
				else 
					bae.setSize(new Dimension(b.getNewSize().getWidth(), b.getNewSize().getHeight()));
			}
		}
		for (ElementAndAlignment a: action.getAlignments()) {
			SModelElement element = index.get(a.getElementId());
			if (element instanceof Alignable) {
				Alignable alignable = (Alignable) element;
				alignable.setAlignment(a.getNewAlignment());
			}
		}
	}
}
