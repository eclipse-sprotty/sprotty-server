/********************************************************************************
 * Copyright (c) 2026 TypeFox and others.
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
package org.eclipse.sprotty.xtext.websocket

import jakarta.websocket.CloseReason
import jakarta.websocket.CloseReason.CloseCodes
import jakarta.websocket.Session
import java.lang.reflect.Proxy
import java.nio.charset.StandardCharsets
import java.util.List
import java.util.concurrent.CompletableFuture
import org.eclipse.lsp4j.jsonrpc.Endpoint
import org.eclipse.lsp4j.jsonrpc.RemoteEndpoint
import org.eclipse.lsp4j.jsonrpc.json.MessageJsonHandler
import org.eclipse.lsp4j.jsonrpc.json.StreamMessageProducer
import org.junit.Test

import static org.junit.Assert.*

class LanguageMessageHandlerTest {

	val List<String> received = newArrayList
	val List<CloseReason> closeReasons = newArrayList

	@Test
	def void testMessageInParts() {
		val handler = createHandler(1000)
		val message = frame(notification('hello'))
		handler.onMessage(message.substring(0, 10), false)
		handler.onMessage(message.substring(10, 30), false)
		handler.onMessage(message.substring(30), true)
		assertEquals(#['test/note "hello"'], received)
		assertEquals(#[], closeReasons)
	}

	@Test
	def void testMessagesInSequence() {
		val handler = createHandler(1000)
		handler.onMessage(frame(notification('first')), true)
		handler.onMessage(frame(notification('second')), true)
		assertEquals(#['test/note "first"', 'test/note "second"'], received)
	}

	@Test
	def void testMessageOfMaximumSize() {
		val message = frame(notification('hello'))
		val handler = createHandler(utf8Length(message))
		handler.onMessage(message.substring(0, 10), false)
		handler.onMessage(message.substring(10), true)
		assertEquals(#['test/note "hello"'], received)
		assertEquals(#[], closeReasons)
	}

	@Test
	def void testMessageTooLarge() {
		val message = frame(notification('hello'))
		val handler = createHandler(utf8Length(message) - 1)
		handler.onMessage(message.substring(0, 10), false)
		handler.onMessage(message.substring(10), true)
		assertEquals(#[], received)
		assertEquals(1, closeReasons.size)
		assertEquals(CloseCodes.TOO_BIG, closeReasons.head.closeCode)
	}

	@Test
	def void testRemainingPartsOfTooLargeMessageAreDropped() {
		val handler = createHandler(100)
		handler.onMessage('x'.repeat(60), false)
		handler.onMessage('x'.repeat(60), false)
		// Would be delivered as a message of its own if the handler kept collecting parts
		handler.onMessage(frame(notification('leak')), false)
		handler.onMessage('', true)
		assertEquals(#[], received)
		assertEquals(1, closeReasons.size)
	}

	@Test
	def void testMessageAfterTooLargeMessage() {
		val handler = createHandler(100)
		handler.onMessage('x'.repeat(60), false)
		handler.onMessage('x'.repeat(60), true)
		handler.onMessage(frame(notification('next')), true)
		assertEquals(#['test/note "next"'], received)
		assertEquals(1, closeReasons.size)
	}

	@Test
	def void testSizeIsCountedInUtf8Bytes() {
		val message = frame(notification('äöü'.repeat(10)))
		assertTrue(utf8Length(message) > message.length)
		val handler = createHandler(message.length)
		handler.onMessage(message, true)
		assertEquals(#[], received)
		assertEquals(1, closeReasons.size)
	}

	@Test(expected = IllegalArgumentException)
	def void testInvalidMaximumSize() {
		createHandler(0)
	}

	private def LanguageMessageHandler createHandler(int maxMessageSize) {
		val jsonHandler = new MessageJsonHandler(emptyMap)
		val localEndpoint = new Endpoint() {
			override request(String method, Object parameter) {
				CompletableFuture.completedFuture(null)
			}
			override notify(String method, Object parameter) {
				received += method + ' ' + parameter
			}
		}
		val serverEndpoint = new RemoteEndpoint([], localEndpoint)
		val session = Proxy.newProxyInstance(Session.classLoader, #[Session], [ proxy, method, args |
			if (method.name == 'close' && args !== null && args.length == 1)
				closeReasons += args.head as CloseReason
			null
		]) as Session
		new LanguageMessageHandler(new StreamMessageProducer(null, jsonHandler), serverEndpoint, session, maxMessageSize)
	}

	private def String notification(String param) {
		'{"jsonrpc":"2.0","method":"test/note","params":"' + param + '"}'
	}

	private def String frame(String content) {
		'Content-Length: ' + utf8Length(content) + '\r\n\r\n' + content
	}

	private def int utf8Length(String s) {
		s.getBytes(StandardCharsets.UTF_8).length
	}

}
