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
 package org.eclipse.sprotty

/**
 * Model elements that implement this interface can be selected.
 */
interface Selectable {
	def void setSelected(boolean isSelected)
	def boolean isSelected()
}

/**
 * Model elements that implement this interface have a position and a size.
 */
interface BoundsAware {
	def Point getPosition()
	def void setPosition(Point position)
	def Dimension getSize()
	def void setSize(Dimension size)
}

/**
 * Used to adjust elements whose bounding box is not at the origin, e.g.
 * labels, or pre-rendered SVG figures.
 */
interface Alignable {
	def Point getAlignment()
	def void setAlignment(Point alignment)
}

interface Scrollable {
	def Point getScroll()
}

interface Zoomable {
	def double getZoom()
}

/**
 * Used to identify model elements that specify a <em>client</em> layout to apply to their children.
 *
 * The children of such elements are ignored by the server-side layout engine because they are
 * already handled by the client.
 *
 * The layout can be further customized using {@link LayoutOptions} on the container or the children.
 * The {@link LayoutOptions} are cascading similar to CSS styles, i.e. they are merged along the
 * containment path of a child.
 */
interface Layouting {
	enum LayoutKind {
		/**
		 * Elements are aligned in left to right direction
		 */
		hbox,

		/**
		 * Elements are aligned in top to bottom direction
		 */
		 vbox,

		/**
		 * Elements are aligned on top of each other
		 */
		stack
	}

	def void setLayout(LayoutKind layout) {
		this.setLayout(layout.toString)
	}

	def String getLayout()
	def void setLayout(String layout)
	def LayoutOptions getLayoutOptions()
}

/**
 * Used to place a child relative to its parent edge.
 */
interface EdgeLayoutable {
 	def EdgePlacement getEdgePlacement()
 	def void setEdgePlacement(EdgePlacement edgePlacement)
}
