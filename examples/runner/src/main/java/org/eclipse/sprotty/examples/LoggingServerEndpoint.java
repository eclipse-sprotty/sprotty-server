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
package org.eclipse.sprotty.examples;

import javax.websocket.EndpointConfig;
import javax.websocket.Session;

import org.eclipse.jetty.util.log.Slf4jLog;
import org.eclipse.sprotty.ActionMessage;
import org.eclipse.sprotty.server.websocket.DiagramServerEndpoint;

public class LoggingServerEndpoint extends DiagramServerEndpoint {

	private static final Slf4jLog LOG = new Slf4jLog(LoggingServerEndpoint.class.getName());
	
	public LoggingServerEndpoint() {
		super();
		setExceptionHandler(exception -> LOG.warn(exception));
	}
	
	@Override
	public void onOpen(final Session session, final EndpointConfig config) {
		LOG.info("Opened connection [" + session.getId() + "]");
		session.setMaxIdleTimeout(120_000);
		super.onOpen(session, config);
	}

	@Override
	public void accept(final ActionMessage actionMessage) {
		LOG.info("SERVER: " + actionMessage.getAction());
		super.accept(actionMessage);
	}

	@Override
	protected void fireMessageReceived(final ActionMessage message) {
		LOG.info("CLIENT: " + message.getAction());
		super.fireMessageReceived(message);
	}
	
}
