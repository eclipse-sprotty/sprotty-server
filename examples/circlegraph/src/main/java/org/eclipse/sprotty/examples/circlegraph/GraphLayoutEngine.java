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

import java.util.Collection;
import java.util.HashSet;
import java.util.Set;

import org.eclipse.elk.alg.force.options.ForceOptions;
import org.eclipse.elk.core.options.CoreOptions;
import org.eclipse.elk.graph.ElkGraphElement;
import org.eclipse.sprotty.SGraph;
import org.eclipse.sprotty.SModelElement;
import org.eclipse.sprotty.SModelRoot;
import org.eclipse.sprotty.SNode;
import org.eclipse.sprotty.layout.ElkLayoutEngine;
import org.eclipse.sprotty.layout.SprottyLayoutConfigurator;

public class GraphLayoutEngine extends ElkLayoutEngine {
	
	private final Set<String> selection = new HashSet<>();
	
	@Override
	public void layout(SModelRoot root) {
		if (root instanceof SGraph) {
			SprottyLayoutConfigurator configurator = new SprottyLayoutConfigurator();
			configurator.configureByType("graph")
					.setProperty(CoreOptions.ALGORITHM, ForceOptions.ALGORITHM_ID)
					.setProperty(CoreOptions.RANDOM_SEED, 0)
					.setProperty(ForceOptions.ITERATIONS, 1000);
			layout((SGraph) root, configurator);
		}
	}
	
	public void setSelection(Collection<String> selection) {
		this.selection.clear();
		this.selection.addAll(selection);
	}
	
	public void clearSelection() {
		this.selection.clear();
	}
	
	@Override
	protected boolean shouldInclude(SModelElement element, SModelElement sParent, ElkGraphElement elkParent,
			LayoutContext context) {
		if (!super.shouldInclude(element, sParent, elkParent, context))
			return false;
		if (!selection.isEmpty() && element instanceof SNode && !selection.contains(element.getId()))
			return false;
		return true;
	}

}
