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

import org.apache.log4j.Logger
import org.eclipse.sprotty.util.TestLogger
import org.eclipse.sprotty.util.TestSetup
import org.junit.Before
import org.junit.Test

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
	
	@Test(expected=NullPointerException)
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
		
		assertEquals('''
			ERROR: Exception while processing ComputedBoundsAction. (java.lang.NullPointerException)
		'''.toString, logger.toString)
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