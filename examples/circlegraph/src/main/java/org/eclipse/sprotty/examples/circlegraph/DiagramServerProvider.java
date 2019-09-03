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
package org.eclipse.sprotty.examples.circlegraph;

import java.util.concurrent.ExecutionException;
import java.util.concurrent.TimeUnit;

import org.eclipse.sprotty.DefaultDiagramServer;
import org.eclipse.sprotty.IDiagramServer;
import org.eclipse.sprotty.SGraph;

import com.google.common.cache.Cache;
import com.google.common.cache.CacheBuilder;
import com.google.inject.Inject;
import com.google.inject.Provider;
import com.google.inject.Singleton;

@Singleton
public class DiagramServerProvider implements IDiagramServer.Provider {
	
	@Inject
	private GraphGenerator graphGenerator;
	@Inject
	private Provider<DefaultDiagramServer> provider;
	
	private final Cache<String, DefaultDiagramServer> cache = CacheBuilder.newBuilder()
			.expireAfterAccess(2, TimeUnit.MINUTES)
			.build();

	@Override
	public IDiagramServer getDiagramServer(String clientId) {
		try {
			return cache.get(clientId, () -> createServer(clientId));
		} catch (ExecutionException e) {
			throw new RuntimeException(e);
		}
	}
	
	private DefaultDiagramServer createServer(String clientId) {
		DefaultDiagramServer server = provider.get();
		server.setNeedsClientLayout(false);
		server.setClientId(clientId);
		SGraph graph = graphGenerator.generateGraph();
		server.setModel(graph);
		return server;
	}

}
