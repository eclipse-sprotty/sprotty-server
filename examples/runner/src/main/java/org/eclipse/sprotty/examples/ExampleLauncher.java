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

import jakarta.websocket.server.ServerEndpointConfig;

import org.eclipse.elk.alg.force.options.ForceMetaDataProvider;
import org.eclipse.jetty.server.Server;
import org.eclipse.jetty.webapp.WebAppContext;
import org.eclipse.jetty.websocket.jakarta.server.config.JakartaWebSocketServletContainerInitializer;
import org.eclipse.sprotty.IDiagramServer;
import org.eclipse.sprotty.examples.circlegraph.CircleGraphModule;
import org.eclipse.sprotty.examples.circlegraph.LayoutSelectionAction;
import org.eclipse.sprotty.layout.ElkLayoutEngine;
import org.eclipse.sprotty.server.json.ActionTypeAdapter;
import org.eclipse.sprotty.server.websocket.DiagramServerEndpoint;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import com.google.inject.Guice;
import com.google.inject.Injector;

public class ExampleLauncher {

	private static final Logger LOG = LoggerFactory.getLogger(ExampleLauncher.class);

	public static void main(String[] args) {
		try {
			ElkLayoutEngine.initialize(new ForceMetaDataProvider());
			new ExampleLauncher().launch();
		} catch (Throwable throwable) {
			ExampleLauncher.LOG.warn("An exception occurred!", throwable);
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
		
		final ServerEndpointConfig.Configurator configurator = new ServerEndpointConfig.Configurator() {
			
			@SuppressWarnings("unchecked")
			@Override
			public <T extends Object> T getEndpointInstance(Class<T> endpointClass) throws InstantiationException {
				DiagramServerEndpoint endpoint = ((LoggingServerEndpoint) super.getEndpointInstance(endpointClass));
				endpoint.setGson(getGson());
				endpoint.setDiagramServerProvider(circleGraphInjector.getInstance(IDiagramServer.Provider.class));
				return (T) endpoint;
			}
		};
		
		JakartaWebSocketServletContainerInitializer.configure(webAppContext, (servletContext, serverContainer) -> {
			serverContainer.addEndpoint(ServerEndpointConfig.Builder
					.create(LoggingServerEndpoint.class, "/circlegraph")
					.configurator(configurator)
					.build());
		});
		
		server.start();
		server.join();
	}

	private Gson getGson() {
		final ActionTypeAdapter.Factory factory = new ActionTypeAdapter.Factory();
		factory.addActionKind(LayoutSelectionAction.KIND, LayoutSelectionAction.class);
		
		return new GsonBuilder().registerTypeAdapterFactory(factory).create();
	}
}
