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
 
package org.eclipse.sprotty.xtext.websocket

import javax.websocket.Session

class WebSocketMessageSender {
	
	/**
	 * If the session provides a text buffer that is large enough, the message is sent
	 * asynchronously, otherwise it is sent synchronously in chunks.
	 */
	def void sendMessage(String message, Session session) {
		if(message.length <= session.maxTextMessageBufferSize) {
			session.asyncRemote.sendText(message)
		} else {
			var currentOffset = 0
			while (currentOffset < message.length) {
				val currentEnd = Math.min(currentOffset + session.maxTextMessageBufferSize, message.length)
				session.basicRemote.sendText(message.substring(currentOffset, currentEnd), currentEnd === message.length)
				currentOffset = currentEnd
			}
		}
	}
}