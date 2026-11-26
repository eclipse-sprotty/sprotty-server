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

import com.google.inject.Inject
import org.eclipse.sprotty.server.json.ActionTypeAdapter
import java.util.LinkedHashMap
import jakarta.websocket.Endpoint
import jakarta.websocket.EndpointConfig
import jakarta.websocket.Session
import org.eclipse.lsp4j.jsonrpc.RemoteEndpoint
import org.eclipse.lsp4j.jsonrpc.json.JsonRpcMethod
import org.eclipse.lsp4j.jsonrpc.json.JsonRpcMethodProvider
import org.eclipse.lsp4j.jsonrpc.json.MessageJsonHandler
import org.eclipse.lsp4j.jsonrpc.json.StreamMessageProducer
import org.eclipse.lsp4j.jsonrpc.services.ServiceEndpoints
import org.eclipse.lsp4j.services.LanguageClient
import org.eclipse.lsp4j.services.LanguageClientAware
import org.eclipse.lsp4j.services.LanguageServer

/**
 * Web socket endpoint for language servers including the diagram extension.
 * <p>
 * The endpoint does not authenticate its clients. Expose it only to trusted clients, or secure it
 * with authentication and connection limits in the web socket container. The size of incoming
 * messages is limited by {@link #getMaxMessageSize()}.
 * </p>
 */
class LanguageServerEndpoint extends Endpoint {
	
	@Inject LanguageServer languageServer
	
	override onOpen(Session session, EndpointConfig config) {
		val supportedMethods = new LinkedHashMap<String, JsonRpcMethod>
		supportedMethods.putAll(ServiceEndpoints.getSupportedMethods(LanguageClient))
		if (languageServer instanceof JsonRpcMethodProvider)
			supportedMethods.putAll(languageServer.supportedMethods)
		
		val jsonHandler = new MessageJsonHandler(supportedMethods) {
			override getDefaultGsonBuilder() {
				ActionTypeAdapter.configureGson(super.defaultGsonBuilder)
			}
		}
		val outgoingMessageStream = new WebSocketMessageConsumer(session.asyncRemote, jsonHandler)
		val serverEndpoint = new RemoteEndpoint(outgoingMessageStream, ServiceEndpoints.toEndpoint(languageServer))
		jsonHandler.setMethodProvider(serverEndpoint)
		val incomingMessageStream = new StreamMessageProducer(null, jsonHandler)
		session.addMessageHandler(new LanguageMessageHandler(incomingMessageStream, serverEndpoint, session, maxMessageSize))
		
		val remoteProxy = ServiceEndpoints.toServiceObject(serverEndpoint, LanguageClient)
		if (languageServer instanceof LanguageClientAware)
			languageServer.connect(remoteProxy)
	}

	/**
	 * The maximum size of a single incoming message in bytes in UTF-8 encoding. When a message exceeds
	 * this size, it is dropped and the session is closed with status code 1009 (message too big).
	 * The maximum text message size configured in the web socket container does not apply because
	 * messages are received in parts. Override this method to change the limit.
	 */
	protected def int getMaxMessageSize() {
		LanguageMessageHandler.DEFAULT_MAX_MESSAGE_SIZE
	}
	
}