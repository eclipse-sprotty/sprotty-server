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
abstract class SModelElement implements Projectable {
	String type
	String id
	List<String> cssClasses
	List<SModelElement> children
	List<String> projectionCssClasses
	Bounds projectedBounds
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
 * Usually the root of a model is also a viewport.
 */
@Accessors
@ToString(skipNulls = true)
class ViewportRootElement extends SModelRoot implements Viewport, BoundsAware {
	Point scroll
	Double zoom
	Point position
	Dimension size

	new() {}
	new(Point scroll, Double zoom) {
		this.scroll = scroll
		this.zoom = zoom
	}
}

/**
 * Root element for graph-like models.
 */
@Accessors
@ToString(skipNulls = true)
class SGraph extends ViewportRootElement implements LayoutableChild {
	LayoutOptions layoutOptions

	new() {
		type = 'graph'
		this.children = newArrayList();
	}
	new(Consumer<SGraph> initializer) {
		this()
		initializer.accept(this)
	}
}

/**
 * Superclass for a lot of elements with bounds being described in shape of a bounding box.
 */
@Accessors
@ToString(skipNulls = true)
abstract class SShapeElement extends SModelElement implements LayoutableChild {
	Point position
	Dimension size
	LayoutOptions layoutOptions
}

/**
 * Model element class for nodes, which are the main entities in a graph. A node can be connected to
 * another node via an SEdge. Such a connection can be direct, i.e. the node is the source or target of
 * the edge, or indirect through a port, i.e. it contains an SPort which is the source or target of the edge.
 */
@Accessors
@ToString(skipNulls = true)
class SNode extends SShapeElement implements LayoutContainer, Selectable, Hoverable, Fadeable  {
	String layout
	EdgePlacement edgePlacement
	boolean selected
	boolean hoverFeedback
	Double opacity

	String anchorKind

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
class SPort extends SShapeElement implements Selectable, Hoverable, Fadeable {
	boolean selected
	boolean hoverFeedback
	Double opacity

	String anchorKind

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
class SEdge extends SModelElement implements Selectable, Hoverable, Fadeable {
	String sourceId
	String targetId
	String routerKind
	List<Point> routingPoints
	boolean selected
	boolean hoverFeedback
	Double opacity

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
class SLabel extends SShapeElement implements Selectable, Alignable, EdgeLayoutable {
	String text
	Point alignment
	EdgePlacement edgePlacement
	boolean selected

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
class SCompartment extends SShapeElement implements LayoutContainer {
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
 * A viewport has a scroll position and a zoom factor. Usually these properties are
 * applied to the root element to enable navigating through the diagram.
 */
interface Viewport extends Scrollable, Zoomable {}

/**
 * A scrollable element has a scroll position, which indicates the top left corner of the
 * visible area.
 */
interface Scrollable {
	def Point getScroll()
}

/**
 * A zoomable element can be scaled so it appears smaller or larger than its actual size.
 * The zoom value 1 is the default scale where the content is drawn with its actual size.
 */
interface Zoomable {
	def Double getZoom()
}

/**
 * An element that can be placed at a specific location using its position property.
 * Feature extension interface for `moveFeature`.
 */
interface Locateable {
	def Point getPosition()
	def void setPosition(Point position)
}

/**
 * Model elements that implement this interface have a position and a size.
 */
interface BoundsAware extends Locateable {
	def Dimension getSize()
	def void setSize(Dimension size)
}

/**
 * Feature extension interface for `layoutableChildFeature`. This is used when the parent
 * element has a `layout` property (meaning it's a `LayoutContainer`).
 */
interface LayoutableChild extends BoundsAware {
	def LayoutOptions getLayoutOptions()
	def void setLayoutOptions(LayoutOptions options)
}

/**
 * Options for client-side layout. This is a union of the different client layout option types,
 * e.g. VBoxLayoutOptions or StackLayoutOptions. It is not used for server layout, which is configured
 * directly in {@link ILayoutEngine} implementations.
 */
@Accessors
@ToString(skipNulls = true)
class LayoutOptions {
	/**
	 * Left-side padding of an element inside its container.
	 */
	Double paddingLeft

	/**
	 * Right-side padding of an element inside its container.
	 */
	Double paddingRight

	/**
	 * Top-side padding of an element inside its container.
	 */
	Double paddingTop

	/**
	 * Bottom-side padding of an element inside its container.
	 */
	Double paddingBottom

	/**
	 * Factor by which a container should be bigger than all its children.
	 *
	 * E.g. choose <code>2</code> for diamond shaped figures or <code>sqrt(2)</code>
	 * for ellipses.
	 */
	Double paddingFactor

	/**
	 * If <code>true</code>, a container gets the minimum size to enclose all its
	 * children.
	 */
	Boolean resizeContainer

	/**
	 * The vertical gap between consecutive children. For 'vbox' layout only.
	 */
	Double vGap

	/**
	 * The horizontal gap between consecutive children. For 'hbox' layout only.
	 */
	Double hGap

	/**
	 * The vertical alignment of the children. For 'hbox' and 'stack' layout only.
	 */
	enum VAlignKind {
		top, center, bottom
	}

	String vAlign

	def setVAlign(VAlignKind vAlignKind) {
		setVAlign(vAlignKind.toString)
	}

	/**
	 * The horizontal alignment of the children. for 'vbox' and 'stack' layout only.
	 */
	enum HAlignKind {
		left, center, right
	}

	String hAlign

	def setHAlign(HAlignKind hAlignKind) {
		setHAlign(hAlignKind.toString)
	}

	/**
	 * The minimum width of an element
	 */
	Double minWidth

	/**
	 * The minimum height of an element
	 */
	Double minHeight

	new() {}

	new(Consumer<LayoutOptions> initializer) {
		initializer.accept(this)
	}
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
interface LayoutContainer extends LayoutableChild {
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
}


/**
 * Feature extension interface for `alignFeature`.
 * Used to adjust elements whose bounding box is not at the origin, e.g. labels
 * or pre-rendered SVG figures.
 */
interface Alignable {
	def Point getAlignment()
	def void setAlignment(Point alignment)
}

/**
 * Feature extension interface for `selectFeature`. The selection status is often considered
 * in the frontend views, e.g. by switching CSS classes.
 */
interface Selectable {
	def void setSelected(boolean isSelected)
	def boolean isSelected()
}

/**
 * Feature extension interface for `hoverFeedbackFeature`. The hover feedback status is often
 * considered in the frontend views, e.g. by switching CSS classes.
 */
interface Hoverable {
    def void setHoverFeedback(boolean isHoverFeedback)
    def boolean isHoverFeedback()
}

/**
 * Feature extension interface for `fadeFeature`. Fading is mostly used to animate when an element
 * appears or disappears.
 */
interface Fadeable {
	def void setOpacity(Double opacity)
    def Double getOpacity()
}

/**
 * Feature extension interface for `expandFeature`.
 * Model elements that implement this interface can be expanded and collapsed.
 */
interface Expandable {
	def void setExpanded(boolean isExpanded)
    def boolean getExpanded()
}

/**
 * Model elements implementing this interface can be displayed on a projection bar.
 * _Note:_ If set, the projectedBounds property will be prefered over the model element bounds.
 * Otherwise model elements also have to be `BoundsAware` so their projections can be shown.
 */
interface Projectable {
    def List<String> getProjectionCssClasses()
    def void setProjectionCssClasses(List<String> projectionCssClasses)
    def Bounds getProjectedBounds()
    def void setProjectedBounds(Bounds projectedBounds)
}


/**
 * Feature extension interface for `edgeLayoutFeature`. This is often applied to
 * {@link SLabel} elements to specify their placement along the containing edge.
 */
interface EdgeLayoutable {
 	def EdgePlacement getEdgePlacement()
 	def void setEdgePlacement(EdgePlacement edgePlacement)
}


/**
 * Each label attached to an edge can be placed on the edge in different ways.
 * With this interface the placement of such a single label is defined.
 */
@Accessors
@ToString(skipNulls = true)
class EdgePlacement {
	enum Side { left, right, top, bottom, on }
	enum MoveMode { edge, free, none }

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

    /**
     * where should the label be moved when move feature is enabled.
     * 'edge' means the label is moved along the edge, 'free' means the label is moved freely, 'none' means the label can not be moved.
     * Default is 'edge'.
     */
    MoveMode moveMode

	new() {}

	new(Consumer<EdgePlacement> initializer) {
		initializer.accept(this)
	}

	def setSide(Side side) {
		this.side = side.toString
	}
}


/**
 * A button is something the user can click.
 */
@Accessors
@ToString(skipNulls = true)
class SButton extends SShapeElement {
	Boolean pressed
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
 * Same as PreRenderedElement, but with a position and a size.
 */
@Accessors
@ToString(skipNulls = true)
class ShapedPreRenderedElement extends PreRenderedElement {
    Point position
    Dimension size
}

/**
 * A `foreignObject` element to be transferred to the DOM within the SVG.
 *
 * This can be useful to to benefit from e.g. HTML rendering features, such as line wrapping, inside of
 * the SVG diagram.  Note that `foreignObject` is not supported by all browsers and SVG viewers may not
 * support rendering the `foreignObject` content.
 *
 * If no dimensions are specified in the schema element, this element will obtain the dimension of
 * its parent to fill the entire available room. Thus, this element requires specified bounds itself
 * or bounds to be available for its parent.
 */
@Accessors
@ToString(skipNulls = true)
class ForeignObjectElement extends ShapedPreRenderedElement {
    /** The namespace to be assigned to the elements inside of the `foreignObject`. */
    String namespace
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

