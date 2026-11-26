/********************************************************************************
 * Copyright (c) 2017-2026 TypeFox and others.
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
import jakarta.websocket.MessageHandler
import jakarta.websocket.Session
import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream
import java.io.FilterInputStream
import java.io.IOException
import java.io.InputStream
import java.nio.charset.StandardCharsets
import java.util.List
import org.apache.log4j.Logger
import org.eclipse.lsp4j.jsonrpc.RemoteEndpoint
import org.eclipse.lsp4j.jsonrpc.json.StreamMessageProducer

/**
 * Web socket message handler that produces LSP4J messages.
 * <p>
 * The handler receives each message in parts, so the maximum text message size configured in the
 * web socket container does not apply to it. Instead, the handler limits the size of a single message
 * to {@code maxMessageSize} bytes in UTF-8 encoding. When a message exceeds that limit, the parts
 * received so far are dropped, the remaining parts of the message are ignored, and the session is closed
 * with status code 1009 (message too big).
 * </p>
 */
class LanguageMessageHandler implements MessageHandler.Partial<String> {

	/**
	 * The default maximum size of a single message in bytes (16 MiB).
	 */
	public static val int DEFAULT_MAX_MESSAGE_SIZE = 16 * 1024 * 1024

	static val LOG = Logger.getLogger(LanguageMessageHandler)

	val StreamMessageProducer messageProducer
	val RemoteEndpoint serverEndpoint
	val Session session
	val int maxMessageSize

	MessageBuffer buffer
	boolean discarding

	/**
	 * Create a handler with the default maximum message size. Since the handler has no access to the
	 * session, it cannot close the session when a message is too large; it only drops that message.
	 *
	 * @deprecated Use {@link #LanguageMessageHandler(StreamMessageProducer, RemoteEndpoint, Session, int)}
	 *     so the session is closed when a message is too large.
	 */
	@Deprecated
	new(StreamMessageProducer messageProducer, RemoteEndpoint serverEndpoint) {
		this(messageProducer, serverEndpoint, null, DEFAULT_MAX_MESSAGE_SIZE)
	}

	/**
	 * @param messageProducer the producer that parses complete messages
	 * @param serverEndpoint the endpoint that receives the parsed messages
	 * @param session the web socket session, which is closed when a message is too large
	 * @param maxMessageSize the maximum size of a single message in bytes in UTF-8 encoding
	 */
	new(StreamMessageProducer messageProducer, RemoteEndpoint serverEndpoint, Session session, int maxMessageSize) {
		if (maxMessageSize <= 0)
			throw new IllegalArgumentException('maxMessageSize must be positive, but was ' + maxMessageSize)
		this.messageProducer = messageProducer
		this.serverEndpoint = serverEndpoint
		this.session = session
		this.maxMessageSize = maxMessageSize
	}

	override onMessage(String partialMessage, boolean last) {
		if (!discarding && partialMessage.length > 0) {
			val long currentSize = if (buffer === null) 0 else buffer.size
			// The UTF-8 encoding of a string has at least as many bytes as the string has chars,
			// so this check rejects a part that is too large before encoding it
			if (currentSize + partialMessage.length > maxMessageSize) {
				discardMessage()
			} else {
				val bytes = partialMessage.getBytes(StandardCharsets.UTF_8)
				if (currentSize + bytes.length > maxMessageSize) {
					discardMessage()
				} else {
					if (buffer === null)
						buffer = new MessageBuffer
					buffer.write(bytes, 0, bytes.length)
				}
			}
		}
		if (last) {
			val message = buffer
			buffer = null
			discarding = false
			if (message !== null) {
				messageProducer.input = message.toInputStream
				messageProducer.listen(serverEndpoint)
			}
		}
	}

	private def void discardMessage() {
		buffer = null
		discarding = true
		messageTooLarge()
	}

	/**
	 * Called when the current message exceeds the maximum size. The parts received so far have already
	 * been dropped, and the remaining parts of the message are ignored. This implementation closes the
	 * session with status code 1009 (message too big).
	 */
	protected def void messageTooLarge() {
		val reason = 'Message exceeds the maximum size of ' + maxMessageSize + ' bytes.'
		if (session === null) {
			LOG.warn(reason + ' The message is dropped.')
			return
		}
		try {
			session.close(new CloseReason(CloseCodes.TOO_BIG, reason))
		} catch (IOException exception) {
			LOG.warn('Failed to close the web socket session.', exception)
		}
	}

	/**
	 * Collects the parts of a message and reads them without copying.
	 */
	private static class MessageBuffer extends ByteArrayOutputStream {

		def InputStream toInputStream() {
			new ByteArrayInputStream(buf, 0, count)
		}

	}

	/**
	 * @deprecated No longer used: {@link LanguageMessageHandler} collects the parts of a message in a single buffer.
	 */
	@Deprecated
	protected static class PartialMessageInputStream extends FilterInputStream {
		
		val List<byte[]> messages
		
		int currentMessageIndex = 0
	
		protected new(List<byte[]> messages) {
			super(new ByteArrayInputStream(messages.head))
			this.messages = messages
		}
		
		protected def boolean nextMessage() {
			currentMessageIndex++
			if (currentMessageIndex < messages.size) {
				in = new ByteArrayInputStream(messages.get(currentMessageIndex))
				return true
			} else {
				return false
			}
		}
		
		override available() throws IOException {
			val current = super.available()
			if (current <= 0 && nextMessage) {
				return super.available()
			} else {
				return current
			}
		}
		
		override read() throws IOException {
			val current = super.read()
			if (current < 0 && nextMessage) {
				return super.read()
			} else {
				return current
			}
		}
		
		override read(byte[] b) throws IOException {
			val current = super.read(b)
			if (current <= 0 && nextMessage) {
				return super.read(b)
			} else {
				return current
			}
		}
		
		override read(byte[] b, int off, int len) throws IOException {
			val current = super.read(b, off, len)
			if (current <= 0 && nextMessage) {
				return super.read(b, off, len)
			} else {
				return current
			}
		}
		
		override markSupported() {
			false
		}
		
	}
	
}