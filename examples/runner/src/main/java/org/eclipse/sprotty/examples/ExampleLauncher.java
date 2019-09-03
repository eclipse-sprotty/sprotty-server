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

import java.net.InetSocketAddress;

import javax.websocket.server.ServerEndpointConfig;

import org.eclipse.elk.alg.force.options.ForceMetaDataProvider;
import org.eclipse.jetty.server.Server;
import org.eclipse.jetty.util.log.Slf4jLog;
import org.eclipse.jetty.webapp.WebAppContext;
import org.eclipse.jetty.websocket.jsr356.server.deploy.WebSocketServerContainerInitializer;
import org.eclipse.sprotty.examples.circlegraph.CircleGraphModule;
import org.eclipse.sprotty.layout.ElkLayoutEngine;

import com.google.inject.Guice;
import com.google.inject.Injector;

public class ExampleLauncher {

	private static final Slf4jLog LOG = new Slf4jLog(ExampleLauncher.class.getName());

	public static void main(String[] args) {
		try {
			ElkLayoutEngine.initialize(new ForceMetaDataProvider());
			new ExampleLauncher().launch();
		} catch (Throwable throwable) {
			ExampleLauncher.LOG.warn(throwable);
			System.exit(1);
		}
	}

	public void launch() throws Exception {
		final Injector circleGraphInjector = Guice.createInjector(new CircleGraphModule());
		
		final Server server = new Server(new InetSocketAddress("localhost", 8080));
		
		final WebAppContext webAppContext = new WebAppContext();
		webAppContext.setContextPath("/");
		webAppContext.setResourceBase("src/main/webapp");
		webAppContext.setWelcomeFiles(new String[] { "index.html" });
		server.setHandler(webAppContext);
		
		WebSocketServerContainerInitializer.configure(webAppContext, (servletContext, serverContainer) -> {
			serverContainer.addEndpoint(ServerEndpointConfig.Builder
					.create(LoggingServerEndpoint.class, "/circlegraph")
					.configurator(new ExampleEndpointConfigurator(circleGraphInjector))
					.build());
		});
		
		server.start();
		server.join();
	}
	
}
