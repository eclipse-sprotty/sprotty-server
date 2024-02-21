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
package org.eclipse.sprotty.layout.test

import com.google.inject.Inject
import org.eclipse.elk.core.math.ElkPadding
import org.eclipse.elk.core.math.KVector
import org.eclipse.elk.core.math.KVectorChain
import org.eclipse.elk.core.options.CoreOptions
import org.eclipse.elk.graph.ElkNode
import org.eclipse.sprotty.Action
import org.eclipse.sprotty.Dimension
import org.eclipse.sprotty.Point
import org.eclipse.sprotty.SCompartment
import org.eclipse.sprotty.SEdge
import org.eclipse.sprotty.SGraph
import org.eclipse.sprotty.SLabel
import org.eclipse.sprotty.SModelRoot
import org.eclipse.sprotty.SNode
import org.eclipse.sprotty.SPort
import org.eclipse.sprotty.layout.ElkLayoutEngine
import org.eclipse.sprotty.layout.SprottyLayoutConfigurator
import org.junit.Test

class ElkLayoutEngineTest extends AbstractElkTest {
	
	private static class TestEngine extends ElkLayoutEngine {
		
		def getConfigurator() {
			val config = new SprottyLayoutConfigurator
			config.configure(ElkNode)
				.setProperty(CoreOptions.ALGORITHM, 'org.eclipse.elk.fixed')
				.setProperty(CoreOptions.PADDING, new ElkPadding)
			return config
		}
		
		override layout(SModelRoot model, Action cause) {
			layout(model as SGraph, configurator, cause)
		}
		
		def layout(SGraph model, (SprottyLayoutConfigurator)=>void initialize) {
			val config = getConfigurator
			initialize.apply(config)
			layout(model, config, null)
		}
		
		def getTransformedGraph(SGraph model) {
			return transformGraph(model, null).elkGraph
		}
		
	}
	
	@Inject TestEngine engine
	
	@Test
	def void testTransformGraphElements() {
		val model = new SGraph [
			id = 'g'
			children = #[
				new SNode [
					id = 'g/node0'
					children = #[
						new SLabel [
							id ='g/node0/label0'
							text = 'Foo'
						],
						new SPort [
							id = 'g/node0/port1'
							children = #[
								new SLabel [
									id = 'g/node0/port1/label0'
									text = 'Bar'
								]
							]
						]
					]
				],
				new SNode [
					id = 'g/node1'
				],
				new SEdge [
					id = 'g/edge2'
					sourceId = 'g/node0/port1'
					targetId = 'g/node1'
					children = #[
						new SLabel [
							id = 'g/edge2/label0'
							text = 'Baz'
						]
					]
				]
			]
		]
		engine.getTransformedGraph(model).assertSerializedTo('''
			graph g
			org.eclipse.sprotty.^layout.type: ^graph
			node g_node0 {
				org.eclipse.sprotty.^layout.type: ^node
				label g_node0_label0: "Foo" {
					org.eclipse.sprotty.^layout.type: ^label
				}
				port g_node0_port1 {
					org.eclipse.sprotty.^layout.type: ^port
					label g_node0_port1_label0: "Bar" {
						org.eclipse.sprotty.^layout.type: ^label
					}
				}
			}
			node g_node1 {
				org.eclipse.sprotty.^layout.type: ^node
			}
			edge g_edge2: g_node0.g_node0_port1 -> g_node1 {
				org.eclipse.sprotty.^layout.type: ^edge
				label g_edge2_label0: "Baz" {
					org.eclipse.sprotty.^layout.type: ^label
				}
			}
		''')
	}
	
	@Test
	def void testTransformCompartments1() {
		val model = new SGraph [
			id = 'g'
			children = #[
				new SNode [ n |
					n.id = 'g/node0'
					n.layout = 'vbox'
					n.position = new Point(100, 100)
					n.size = new Dimension(35, 35)
					n.children = #[
						new SLabel [ // Skipped because the parent node has a client layout
							id = n.id + '/label0'
						],
						new SCompartment [ c |
							c.id = n.id + '/comp1'
							c.layout = 'hbox'
							c.position = new Point(0, 10)
							c.size = new Dimension(5, 5)
							c.children = #[
								new SLabel [ // Skipped because the parent compartment has a client layout
									id = c.id + '/label0'
								]
							]
						],
						new SCompartment [ c |
							c.id = n.id + '/comp2'
							c.position = new Point(10, 10)
							c.size = new Dimension(15, 15)
							c.children = #[
								new SLabel [
									id = c.id + '/label0'
									text = "Foo"
								]
							]
						]
					]
				]
			]
		]
		engine.getTransformedGraph(model).assertSerializedTo('''
			graph g
			org.eclipse.sprotty.^layout.type: ^graph
			node g_node0 {
				layout [
					position: 100, 100
					size: 35, 35
				]
				org.eclipse.sprotty.^layout.type: ^node
				elk.padding: "[top=10.0,left=10.0,bottom=10.0,right=10.0]"
				label g_node0_comp2_label0: "Foo" {
					org.eclipse.sprotty.^layout.type: ^label
				}
			}
		''')
	}
	
	@Test
	def void testTransformCompartments2() {
		val model = new SGraph [
			id = 'g'
			children = #[
				new SNode [
					id = 'g/node0'
					layout = 'vbox'
					position = new Point(100, 100)
					size = new Dimension(55, 55)
					children = #[
						new SCompartment [
							id = 'g/node0/comp0'
							layout = 'hbox'
							position = new Point(10, 10)
							size = new Dimension(35, 35)
							children = #[
								new SCompartment [
									id = 'g/node0/comp0/comp0'
									position = new Point(10, 10)
									size = new Dimension(15, 15)
									children = #[
										new SNode[
											id = 'g/node0/comp0/comp0/node0'
										]
									]
								]
							]
						]
					]
				]
			]
		]
		engine.getTransformedGraph(model).assertSerializedTo('''
			graph g
			org.eclipse.sprotty.^layout.type: ^graph
			node g_node0 {
				layout [
					position: 100, 100
					size: 55, 55
				]
				org.eclipse.sprotty.^layout.type: ^node
				elk.padding: "[top=20.0,left=20.0,bottom=20.0,right=20.0]"
				node g_node0_comp0_comp0_node0 {
					org.eclipse.sprotty.^layout.type: ^node
				}
			}
		''')
	}
	
	@Test
	def void testLayoutCrossHierarchyEdge1() {
		val model = new SGraph [
			id = 'g'
			children = #[
				new SNode [
					id = 'g/node0'
					position = new Point(10, 10)
					children = #[
						new SNode [
							id = 'g/node0/node0'
							position = new Point(10, 10)
						]
					]
				],
				new SNode [
					id = 'g/node1'
					position = new Point(40, 10)
					children = #[
						new SNode [
							id = 'g/node1/node0'
							position = new Point(10, 10)
						],
						new SEdge [ // Added as child of 'g' in the ELK graph
							id = 'g/node1/edge1'
							sourceId = 'g/node0/node0'
							targetId = 'g/node1/node0'
						]
					]
				]
			]
		]
		engine.layout(model) [
			val bendPoint = new KVectorChain(new KVector(20, 20), new KVector(35, 25), new KVector(50, 20))
			configureById('g/node1/edge1').setProperty(CoreOptions.BEND_POINTS, bendPoint)
		]
		model.children.get(1).children.get(1).assertSerializedTo('''
			SEdge [
			  sourceId = "g/node0/node0"
			  targetId = "g/node1/node0"
			  routingPoints = ArrayList (
			    Point [
			      x = -20.0
			      y = 10.0
			    ],
			    Point [
			      x = -5.0
			      y = 15.0
			    ],
			    Point [
			      x = 10.0
			      y = 10.0
			    ]
			  )
			  selected = false
			  hoverFeedback = false
			  type = "edge"
			  id = "g/node1/edge1"
			]
		''')
	}
	
	@Test
	def void testLayoutCrossHierarchyEdge2() {
		val model = new SGraph [
			id = 'g'
			children = #[
				new SNode [
					id = 'g/node0'
					position = new Point(10, 10)
					children = #[
						new SNode [
							id = 'g/node0/node0'
							position = new Point(10, 10)
						],
						new SNode [
							id = 'g/node0/node1'
							position = new Point(40, 10)
						]
					]
				],
				new SNode [
					id = 'g/node1'
					position = new Point(10, 40)
					children = #[
						new SEdge [ // Added as child of 'g/node0' in the ELK graph
							id = 'g/node1/edge0'
							sourceId = 'g/node0/node0'
							targetId = 'g/node0/node1'
						]
					]
				]
			]
		]
		engine.layout(model) [
			val bendPoint = new KVectorChain(new KVector(10, 10), new KVector(25, 15), new KVector(40, 10))
			configureById('g/node1/edge0').setProperty(CoreOptions.BEND_POINTS, bendPoint)
		]
		model.children.get(1).children.get(0).assertSerializedTo('''
			SEdge [
			  sourceId = "g/node0/node0"
			  targetId = "g/node0/node1"
			  routingPoints = ArrayList (
			    Point [
			      x = 10.0
			      y = -20.0
			    ],
			    Point [
			      x = 25.0
			      y = -15.0
			    ],
			    Point [
			      x = 40.0
			      y = -20.0
			    ]
			  )
			  selected = false
			  hoverFeedback = false
			  type = "edge"
			  id = "g/node1/edge0"
			]
		''')
	}
	
	@Test
	def void testLayoutCrossHierarchyEdge3() {
		val model = new SGraph [
			id = 'g'
			children = #[
				new SNode [
					id = 'g/node0'
					position = new Point(10, 10)
					children = #[
						new SNode [
							id = 'g/node0/node0'
							position = new Point(10, 10)
						]
					]
				],
				new SNode [
					id = 'g/node1'
					position = new Point(40, 10)
					children = #[
						new SNode [
							id = 'g/node1/node0'
							position = new Point(10, 10)
						],
						new SEdge [ // Added as child of 'g' in the ELK graph
							id = 'g/node1/edge1'
							sourceId = 'g/node1/node0'
							targetId = 'g/node0/node0'
						]
					]
				]
			]
		]
		engine.layout(model) [
			val bendPoint = new KVectorChain(new KVector(50, 20), new KVector(35, 25), new KVector(20, 20))
			configureById('g/node1/edge1').setProperty(CoreOptions.BEND_POINTS, bendPoint)
		]
		model.children.get(1).children.get(1).assertSerializedTo('''
			SEdge [
			  sourceId = "g/node1/node0"
			  targetId = "g/node0/node0"
			  routingPoints = ArrayList (
			    Point [
			      x = 10.0
			      y = 10.0
			    ],
			    Point [
			      x = -5.0
			      y = 15.0
			    ],
			    Point [
			      x = -20.0
			      y = 10.0
			    ]
			  )
			  selected = false
			  hoverFeedback = false
			  type = "edge"
			  id = "g/node1/edge1"
			]
		''')
	}
	
	@Test
	def void testLayoutCrossHierarchyEdge4() {
		val model = new SGraph [
			id = 'g'
			children = #[
				new SNode [
					id = 'g/node0'
					position = new Point(10, 10)
					children = #[
						new SNode [
							id = 'g/node0/node0'
							position = new Point(10, 10)
						],
						new SEdge [ // Added as child of 'g' in the ELK graph
							id = 'g/node0/edge1'
							sourceId = 'g/node0/node0'
							targetId = 'g/node1/node0'
						]
					]
				],
				new SNode [
					id = 'g/node1'
					position = new Point(40, 10)
					children = #[
						new SNode [
							id = 'g/node1/node0'
							position = new Point(10, 10)
						]
					]
				]
			]
		]
		engine.layout(model) [
			val bendPoint = new KVectorChain(new KVector(20, 20), new KVector(35, 25), new KVector(50, 20))
			configureById('g/node0/edge1').setProperty(CoreOptions.BEND_POINTS, bendPoint)
		]
		model.children.get(0).children.get(1).assertSerializedTo('''
			SEdge [
			  sourceId = "g/node0/node0"
			  targetId = "g/node1/node0"
			  routingPoints = ArrayList (
			    Point [
			      x = 10.0
			      y = 10.0
			    ],
			    Point [
			      x = 25.0
			      y = 15.0
			    ],
			    Point [
			      x = 40.0
			      y = 10.0
			    ]
			  )
			  selected = false
			  hoverFeedback = false
			  type = "edge"
			  id = "g/node0/edge1"
			]
		''')
	}
	
	
	
}