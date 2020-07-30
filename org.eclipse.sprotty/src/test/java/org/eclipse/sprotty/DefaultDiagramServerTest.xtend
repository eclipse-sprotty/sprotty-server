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

import java.util.concurrent.ExecutionException
import org.apache.log4j.Logger
import org.eclipse.sprotty.util.RejectException
import org.eclipse.sprotty.util.TestLogger
import org.eclipse.sprotty.util.TestSetup
import org.junit.Before
import org.junit.Test

import static java.util.Collections.*
import static org.junit.Assert.*

class DefaultDiagramServerTest {
	
	TestLogger logger
	
	@Before
	def void setup() {
		logger = new TestLogger
		val rootLogger = Logger.rootLogger
		rootLogger.removeAllAppenders()
		rootLogger.addAppender(logger)
		
		DefaultDiagramServer.nextRequestId.set(0)
	}
	
	@Test
	def void testRequestModelNoLayout() {
		val server = new TestSetup().createServer()
		server.model = new SModelRoot[
			type = 'root'
			id = 'my-root'
		]
		val messages = newArrayList
		server.remoteEndpoint = [m | messages.add(m)]
		server.accept(new ActionMessage[
			action = new RequestModelAction[
				requestId = 'foo001'
				options = #{
					DiagramOptions.OPTION_NEEDS_CLIENT_LAYOUT -> 'false',
					DiagramOptions.OPTION_NEEDS_SERVER_LAYOUT -> 'false'
				}
			]
		])
		logger.print()
		
		assertEquals(#[
			new ActionMessage[
				action = new SetModelAction[
					responseId = 'foo001'
					newRoot = server.model
				]
			]
		].toString, messages.toString)
	}
	
	@Test
	def void testRequestModelServerLayout() {
		val server = new TestSetup[
			layoutEngine = DummyLayoutEngine
		].createServer()
		server.model = new SModelRoot[
			type = 'root'
			id = 'my-root'
			children = #[new SNode[
				type = 'node'
				id = 'my-node'
			]]
		]
		val messages = newArrayList
		server.remoteEndpoint = [m | messages.add(m)]
		server.accept(new ActionMessage[
			action = new RequestModelAction[
				requestId = 'foo001'
				options = #{
					DiagramOptions.OPTION_NEEDS_CLIENT_LAYOUT -> 'false',
					DiagramOptions.OPTION_NEEDS_SERVER_LAYOUT -> 'true'
				}
			]
		])
		logger.print()
		
		assertEquals(#[
			new ActionMessage[
				action = new SetModelAction[
					responseId = 'foo001'
					newRoot = server.model
				]
			]
		].toString, messages.toString)
		assertEquals(DummyLayoutEngine.X, (server.model.children.head as BoundsAware).position.x, 0.0001)
		assertEquals(DummyLayoutEngine.Y, (server.model.children.head as BoundsAware).position.y, 0.0001)
	}
	
	@Test
	def void testRequestModelClientLayout() {
		val server = new TestSetup().createServer()
		server.model = new SModelRoot[
			type = 'root'
			id = 'my-root'
		]
		val messages = newArrayList
		server.remoteEndpoint = [m | messages.add(m)]
		server.accept(new ActionMessage[
			action = new RequestModelAction[
				requestId = 'foo001'
				options = #{
					DiagramOptions.OPTION_NEEDS_CLIENT_LAYOUT -> 'true',
					DiagramOptions.OPTION_NEEDS_SERVER_LAYOUT -> 'false'
				}
			]
		])
		logger.print()
		
		assertEquals(#[
			new ActionMessage[
				action = new RequestBoundsAction[
					newRoot = server.model
				]
			]
		].toString, messages.toString)
	}
	
	@Test
	def void testRequestModelFullLayout() {
		val server = new TestSetup[
			layoutEngine = DummyLayoutEngine
		].createServer()
		server.model = new SModelRoot[
			type = 'root'
			id = 'my-root'
			children = #[new SNode[
				type = 'node'
				id = 'my-node'
			]]
		]
		val messages = newArrayList
		server.remoteEndpoint = [m | messages.add(m)]
		server.accept(new ActionMessage[
			action = new RequestModelAction[
				requestId = 'foo001'
				options = #{
					DiagramOptions.OPTION_NEEDS_CLIENT_LAYOUT -> 'true',
					DiagramOptions.OPTION_NEEDS_SERVER_LAYOUT -> 'true'
				}
			]
		])
		server.accept(new ActionMessage[
			action = new ComputedBoundsAction[
				responseId = 'server_1'
				revision = 1
				bounds = emptyList
				alignments = emptyList
			]
		])
		logger.print()
		
		assertEquals(#[
			new ActionMessage[
				action = new RequestBoundsAction[
					requestId = 'server_1'
					newRoot = server.model
				]
			],
			new ActionMessage[
				action = new SetModelAction[
					responseId = 'foo001'
					newRoot = server.model
				]
			]
		].toString, messages.toString)
		assertEquals(DummyLayoutEngine.X, (server.model.children.head as BoundsAware).position.x, 0.0001)
		assertEquals(DummyLayoutEngine.Y, (server.model.children.head as BoundsAware).position.y, 0.0001)
	}
	
	@Test
	def void testThrowingServerLayout() {
		val server = new TestSetup[
			layoutEngine = ThrowingLayoutEngine
		].createServer()
		server.model = new SModelRoot[
			type = 'root'
			id = 'my-root'
		]
		val messages = newArrayList
		server.remoteEndpoint = [m | messages.add(m)]
		server.accept(new ActionMessage[
			action = new RequestModelAction[
				requestId = 'foo001'
				options = #{
					DiagramOptions.OPTION_NEEDS_CLIENT_LAYOUT -> 'false',
					DiagramOptions.OPTION_NEEDS_SERVER_LAYOUT -> 'true'
				}
			]
		])
	
		assertEquals(#[
			new ActionMessage[
				action = new RejectAction[
					responseId = 'foo001'
					message = 'NullPointerException'
				]
			]
		].toString, messages.toString)
	}
	
	@Test
	def void testThrowingFullLayout() {
		val server = new TestSetup[
			layoutEngine = ThrowingLayoutEngine
		].createServer()
		server.model = new SModelRoot[
			type = 'root'
			id = 'my-root'
		]
		val messages = newArrayList
		server.remoteEndpoint = [m | messages.add(m)]
		server.accept(new ActionMessage[
			action = new RequestModelAction[
				requestId = 'foo001'
				options = #{
					DiagramOptions.OPTION_NEEDS_CLIENT_LAYOUT -> 'true',
					DiagramOptions.OPTION_NEEDS_SERVER_LAYOUT -> 'true'
				}
			]
		])
		server.accept(new ActionMessage[
			action = new ComputedBoundsAction[
				responseId = 'server_1'
				revision = 1
				bounds = emptyList
				alignments = emptyList
			]
		])
		
		assertEquals(#[
			new ActionMessage[
				action = new RequestBoundsAction[
					requestId = 'server_1'
					newRoot = server.model
				]
			],
			new ActionMessage[
				action = new RejectAction[
					responseId = 'foo001'
					message = 'NullPointerException'
				]
			]
		].toString, messages.toString)
		assertEquals('''
			ERROR: Exception while processing ComputedBoundsAction. (java.lang.NullPointerException)
		'''.toString.trim, logger.toString.trim)
	}
	
	@Test
	def void testNoPopupModelFactory() {
		val server = new TestSetup().createServer()
		server.model = new SModelRoot[
			type = 'root'
			id = 'my-root'
		]
		val messages = newArrayList
		server.remoteEndpoint = [m | messages.add(m)]
		server.accept(new ActionMessage[
			action = new RequestPopupModelAction[
				requestId = 'foo001'
				elementId = 'my-root'
			]
		])
	
		assertEquals(#[
			new ActionMessage[
				action = new RejectAction[
					responseId = 'foo001'
					message = 'No popup model available.'
				]
			]
		].toString, messages.toString)
	}
	
	@Test
	def void testRequestToClient() {
		val server = new TestSetup().createServer()
		val future = server.request(new GetSelectionAction)
		server.accept(new ActionMessage[
			action = new SelectionResult[
				responseId = 'server_1'
				selectedElementsIDs = #['1', '2', '3']
			]
		])
		val result = future.get
		assertEquals(#['1', '2', '3'], result.selectedElementsIDs)
	}
	
	@Test
	def void testRequestToClientRejected() {
		val server = new TestSetup().createServer()
		val future = server.request(new GetSelectionAction)
		server.accept(new ActionMessage[
			action = new RejectAction[
				responseId = 'server_1'
				message = 'foo bar'
			]
		])
		try {
			future.get
			fail('Expected an ExecutionException')
		} catch (ExecutionException exc) {
			assertTrue(exc.cause instanceof RejectException)
			val cause = exc.cause as RejectException
			assertEquals('foo bar', cause.action.message)
		}
	}
	
	/**
	 * Selection state should be updated when dispatching and accepting {@link SelectAction}s.
	 */
	@Test
	def void testSelect() {
		val server = new TestSetup().createServer()
		server.remoteEndpoint = []
		server.model = new SModelRoot [
			id = "root"
			children = #[
				new SNode[id = "node1"],
				new SNode[id = "node2"]
			]
		]

		val selectNode1 = new SelectAction [
			selectedElementsIDs = #["node1"]
			deselectedElementsIDs = #["node2"]
		]

		val selectNode2 = new SelectAction [
			selectedElementsIDs = #["node2"]
			deselectedElementsIDs = #["node1"]
		]

		server.accept(new ActionMessage[action = selectNode1])
		assertEquals("Accept select", server.diagramState.selectedElements, singleton("node1"))
		server.accept(new ActionMessage[action = selectNode2])
		assertEquals("Accept select/deselect", server.diagramState.selectedElements, singleton("node2"))

		server.dispatch(selectNode1)
		assertEquals("Dispatch select", server.diagramState.selectedElements, singleton("node1"))
		server.dispatch(selectNode2)
		assertEquals("Dispatch select/deselect", server.diagramState.selectedElements, singleton("node2"))
	}
	
	/**
	 * Selection state should be updated when dispatching and accepting {@link SelectAllAction}s.
	 */
	@Test
	def void testSelectAll() {
		val server = new TestSetup().createServer()
		server.remoteEndpoint = []
		server.model = new SModelRoot [
			id = "root"
			children = #[
				new SNode[id = "node1"],
				new SNode[id = "node2"]
			]
		]

		val allIds = #["root", "node1", "node2"].toSet

		server.accept(new ActionMessage[action = new SelectAllAction[select = true]])
		assertEquals("Accept select all", server.diagramState.selectedElements, allIds)
		server.accept(new ActionMessage[action = new SelectAllAction[select = false]])
		assertEquals("Accept deselect all", server.diagramState.selectedElements, emptySet)

		server.dispatch(new SelectAllAction[select = true])
		assertEquals("Dispatch select all", server.diagramState.selectedElements, allIds)
		server.dispatch(new SelectAllAction[select = false])
		assertEquals("Dispatch deselect all", server.diagramState.selectedElements, emptySet)
	}
	
	/**
	 * Setting a new model should clear any previous selection.
	 */
	@Test
	def void testSelectSetModel() {
		val server = new TestSetup().createServer()
		server.model = new SModelRoot[id = "root"]
		server.accept(new ActionMessage[action = new SelectAllAction[select = true]])
		server.model = new SModelRoot[id = "root"]
		assertEquals("Selection after set model", server.diagramState.selectedElements, emptySet)
	}
	
	/**
	 * Updating a model should retain the selection (but remove elements that do not exist anymore).
	 */
	 @Test
	def void testSelectionUpdateModel() {
		val server = new TestSetup().createServer()
		server.model = new SModelRoot[
			id = "root"
			children = #[
				new SNode[id = "node1"],
				new SNode[id = "node2"]
			]
		]
		server.accept(new ActionMessage[action = new SelectAllAction[select = true]])
		server.updateModel(new SModelRoot[
			id = "root"
			children = #[
				new SNode[id = "node1"],
				new SNode[id = "node3"]
			]
		])
		assertEquals("Selection after update", server.diagramState.selectedElements, #["root", "node1"].toSet)
	}
	
	
	//-------------------- UTILITY CLASSES --------------------
	
	private static class DummyLayoutEngine implements ILayoutEngine {
		static val X = 1
		static val Y = 2
		override layout(SModelRoot root, Action cause) {
			root.children.filter(BoundsAware).forEach[
				position = new Point(X, Y)
			]
		}
	}
	
	private static class ThrowingLayoutEngine implements ILayoutEngine {
		override layout(SModelRoot root, Action cause) {
			throw new NullPointerException
		}
	}
	
}