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

import java.util.ArrayList;
import java.util.Random;

import org.eclipse.sprotty.Dimension;
import org.eclipse.sprotty.SEdge;
import org.eclipse.sprotty.SGraph;
import org.eclipse.sprotty.SModelElement;
import org.eclipse.sprotty.SNode;
import org.eclipse.sprotty.util.IdCache;

import com.google.inject.Inject;
import com.google.inject.Provider;

public class GraphGenerator {
	
	private static final int NODE_COUNT = 50;
	private static final int ADD_EDGE_COUNT = 50;
	private static final double NODE_SIZE = 60;
	
	@Inject
	private Provider<IdCache<SModelElement>> idCacheProvider;
	
	private Random random = new Random();
	
	public SGraph generateGraph() {
		Context ctx = new Context();
		ctx.idCache = idCacheProvider.get();
		return new SGraph(graph -> {
			graph.setId("graph");
			graph.setChildren(new ArrayList<>(2 * NODE_COUNT + ADD_EDGE_COUNT));
			
			// Generate nodes
			for (int n = 0; n < NODE_COUNT; n++) {
				graph.getChildren().add(generateNode(ctx));
			}
			
			// Generate one connected edge per node
			for (int n1 = 0; n1 < NODE_COUNT; n1++) {
				int n2;
				do {
					n2 = random.nextInt(NODE_COUNT);
				} while (n1 == n2);
				graph.getChildren().add(generateEdge(
						graph.getChildren().get(n1).getId(),
						graph.getChildren().get(n2).getId(),
						ctx));
			}
			
			// Generate additional edges
			for (int e = 0; e < ADD_EDGE_COUNT; e++) {
				int n1, n2;
				do {
					n1 = random.nextInt(NODE_COUNT);
					n2 = random.nextInt(NODE_COUNT);
				} while (n1 == n2);
				graph.getChildren().add(generateEdge(
						graph.getChildren().get(n1).getId(),
						graph.getChildren().get(n2).getId(),
						ctx));
			}
		});
	}
	
	private SNode generateNode(Context ctx) {
		return new SNode(node -> {
			node.setId(ctx.idCache.uniqueId(node, "node", 1));
			node.setSize(new Dimension(NODE_SIZE, NODE_SIZE));
		});
	}
	
	private SEdge generateEdge(String sourceId, String targetId, Context ctx) {
		return new SEdge(edge -> {
			edge.setId(ctx.idCache.uniqueId(edge, "edge", 1));
			edge.setSourceId(sourceId);
			edge.setTargetId(targetId);
		});
	}
	
	private static class Context {
		IdCache<SModelElement> idCache;
	}

}
