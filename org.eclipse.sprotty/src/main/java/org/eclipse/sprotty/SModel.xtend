/********************************************************************************
 * Copyright (c) 2017-2018 TypeFox and others.
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

import java.util.List
import java.util.function.Consumer
import org.eclipse.xtend.lib.annotations.Accessors
import org.eclipse.xtend.lib.annotations.ToString

/**
 * Base class for all elements of the diagram model. This is a Java representation of the TypeScript
 * interface {@code SModelElementSchema}, so it is meant to be serialized to JSON so it can be
 * transferred to the client.
 * Each model element must have a unique ID and a type that is used to look up its view.
 */
@Accessors
@ToString(skipNulls = true)
abstract class SModelElement {
	String type
	String id
	List<String> cssClasses
	List<SModelElement> children
	String trace
}

/**
 * Base class for the root element of the diagram model tree.
 */
@Accessors
@ToString(skipNulls = true)
class SModelRoot extends SModelElement {

	public static final SModelRoot EMPTY_ROOT = new SModelRoot [
		type = "NONE"
		id = "EMPTY"
	]

	Bounds canvasBounds
	int revision

	new() {
		type = 'root'
	}
	new(Consumer<SModelRoot> initializer) {
		this()
		initializer.accept(this)
	}
}

/**
 * Root element for graph-like models.
 */
@Accessors
@ToString(skipNulls = true)
class SGraph extends SModelRoot implements BoundsAware {
	Point position
	Dimension size
	LayoutOptions layoutOptions

	new() {
		type = 'graph'
	}
	new(Consumer<SGraph> initializer) {
		this()
		initializer.accept(this)
	}
}

/**
 * Superclass for a lot of elements.
 */
@Accessors
@ToString(skipNulls = true)
abstract class SShapeElement extends SModelElement implements BoundsAware {
	Point position
	Dimension size
	LayoutOptions layoutOptions
}

/**
 * Model element class for nodes, which are connectable entities in a graph. A node can be connected to
 * another node via an SEdge. Such a connection can be direct, i.e. the node is the source or target of
 * the edge, or indirect through a port, i.e. it contains an SPort which is the source or target of the edge.
 */
@Accessors
@ToString(skipNulls = true)
class SNode extends SShapeElement implements Layouting, EdgeLayoutable  {
	String layout
	EdgePlacement edgePlacement

	new() {
		type = 'node'
	}
	new(Consumer<SNode> initializer) {
		this()
		initializer.accept(this)
	}
}

/**
 * A port is a connection point for edges. It should always be contained in an SNode.
 */
@Accessors
@ToString(skipNulls = true)
class SPort extends SShapeElement {
	new() {
		type = 'port'
	}
	new(Consumer<SPort> initializer) {
		this()
		initializer.accept(this)
	}
}

/**
 * Model element class for edges, which are the connectors in a graph. An edge has a source and a target,
 * each of which can be either a node or a port. The source and target elements are referenced via their
 * ids and can be resolved with an {@link SModelIndex}.
 */
@Accessors
@ToString(skipNulls = true)
class SEdge extends SModelElement {
	String sourceId
	String targetId
	List<Point> routingPoints

	new() {
		type = 'edge'
	}
	new(Consumer<SEdge> initializer) {
		this()
		initializer.accept(this)
	}
}

/**
 * A label can be attached to a node, edge, or port, and contains some text to be rendered in its view.
 */
@Accessors
@ToString(skipNulls = true)
class SLabel extends SShapeElement implements Alignable, EdgeLayoutable {
	String text
	Point alignment
	EdgePlacement edgePlacement

	new() {
		type = 'label'
	}
	new(Consumer<SLabel> initializer) {
		this()
		initializer.accept(this)
	}
}

/**
 * A compartment is used to group multiple child elements such as labels of a node. Usually a {@code vbox}
 * or {@code hbox} layout is used to arrange these children.
 */
@Accessors
@ToString(skipNulls = true)
class SCompartment extends SShapeElement implements Layouting {
	String layout

	new() {
		type = 'comp'
	}
	new(Consumer<SCompartment> initializer) {
		this()
		initializer.accept(this)
	}
}

/**
 * A button is something the user can click.
 */
@Accessors
@ToString(skipNulls = true)
class SButton extends SShapeElement implements BoundsAware {
	Boolean enabled

	new() {
		type = 'button'
	}
	new(Consumer<SButton> initializer) {
		this()
		initializer.accept(this)
	}
}

/**
 * Options for client-side layout. This is a union of the different client layout option types,
 * e.g. VBoxLayoutOptions or StackLayoutOptions. It is not used for server layout, which is configured
 * directly in {@link ILayoutEngine} implementations.
 */
@Accessors
@ToString(skipNulls = true)
class LayoutOptions {
	Double paddingLeft
	Double paddingRight
	Double paddingTop
	Double paddingBottom
	Double paddingFactor
	Boolean resizeContainer
	Double vGap
	Double hGap
	String vAlign
	String hAlign
	Double minWidth
	Double minHeight

	new() {}

	new(Consumer<LayoutOptions> initializer) {
		initializer.accept(this)
	}
}

/**
 * Options for client-side edge layout. Used to place and rotate child elements of edges.
 */
@Accessors
@ToString(skipNulls = true)
class EdgePlacement {
	enum Side { left, right, top, bottom, on }

	/**
	 * A value between 0 (source) and 1 (target) describing the position along the edge.
	 */
	Double position

	/**
	 * Offset of the element to the edge in pixels
	 */
	Double offset

	/**
	 * Where to place the element relative to the edges direction.
	 */
	@Accessors(PUBLIC_GETTER)
	String side

	/**
	 * Whether to rotate the element such that it is tangential to the edge or not.
	 * Defaults to true.
	 */
	Boolean rotate

	new() {}

	new(Consumer<EdgePlacement> initializer) {
		initializer.accept(this)
	}

	def setSide(Side side) {
		this.side = side.toString
	}
}

/**
 * Root model element class for HTML content. Usually this is rendered with a `div` DOM element.
 */
@Accessors
@ToString(skipNulls = true)
class HtmlRoot extends SModelRoot {
    List<String> classes

	new() {
		type = 'html'
	}
	new(Consumer<HtmlRoot> initializer) {
		this()
		initializer.accept(this)
	}
}

/**
 * Pre-rendered elements contain HTML or SVG code to be transferred to the DOM. This can be useful to
 * render complex figures or to compute the view on the server instead of the client code.
 */
@Accessors
@ToString(skipNulls = true)
class PreRenderedElement extends SModelElement {
	String code

	new() {
		type = 'pre-rendered'
	}
	new(Consumer<PreRenderedElement> initializer) {
		this()
		initializer.accept(this)
	}
}

/**
 * A small decorator marking issues on an SModelElement.
 */
@Accessors
@ToString(skipNulls = true)
class SIssueMarker extends SShapeElement {

	List<SIssue> issues

	new() {
		type = 'marker'
	}
	new(Consumer<SIssueMarker> initializer) {
		this()
		initializer.accept(this)
	}

}

@Accessors
@ToString(skipNulls = true)
class SIssue {
	enum Severity { error, warning, info }

	String message

	@Accessors(PUBLIC_GETTER)
	String severity

	new() {}
	new(Consumer<SIssue> initializer) {
		initializer.accept(this)
	}

	def setSeverity(Severity severity) {
		this.severity = severity.toString
	}
}

