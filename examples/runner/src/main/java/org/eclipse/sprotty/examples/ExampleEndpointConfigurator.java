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

import jakarta.websocket.server.ServerEndpointConfig;

import org.eclipse.sprotty.IDiagramServer;
import org.eclipse.sprotty.examples.circlegraph.LayoutSelectionAction;
import org.eclipse.sprotty.server.json.ActionTypeAdapter;
import org.eclipse.sprotty.server.websocket.DiagramServerEndpoint;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import com.google.inject.Injector;

public class ExampleEndpointConfigurator extends ServerEndpointConfig.Configurator {

	private final Injector injector;

	public ExampleEndpointConfigurator(Injector injector) {
		this.injector = injector;
	}

	@SuppressWarnings("unchecked")
	@Override
	public <T extends Object> T getEndpointInstance(Class<T> endpointClass) throws InstantiationException {
		DiagramServerEndpoint endpoint = ((DiagramServerEndpoint) super.getEndpointInstance(endpointClass));
		endpoint.setGson(getGson());
		endpoint.setDiagramServerProvider(injector.getInstance(IDiagramServer.Provider.class));
		return (T) endpoint;
	}
	
	private Gson getGson() {
		GsonBuilder builder = new GsonBuilder();
		ActionTypeAdapter.Factory factory = new ActionTypeAdapter.Factory();
		factory.addActionKind(LayoutSelectionAction.KIND, LayoutSelectionAction.class);
		builder.registerTypeAdapterFactory(factory);
		return builder.create();
	}
	
}
