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

import org.eclipse.sprotty.DefaultDiagramServer;
import org.eclipse.sprotty.IDiagramExpansionListener;
import org.eclipse.sprotty.IDiagramOpenListener;
import org.eclipse.sprotty.IDiagramSelectionListener;
import org.eclipse.sprotty.IDiagramServer;
import org.eclipse.sprotty.ILayoutEngine;
import org.eclipse.sprotty.IModelUpdateListener;
import org.eclipse.sprotty.IPopupModelFactory;

import com.google.inject.Binder;
import com.google.inject.Module;

public class CircleGraphModule implements Module {

	@Override
	public void configure(Binder binder) {
		binder.bind(IDiagramServer.Provider.class).to(DiagramServerProvider.class);
		binder.bind(DefaultDiagramServer.class).to(CircleGraphDiagramServer.class);
		binder.bind(ILayoutEngine.class).to(GraphLayoutEngine.class);
		
		binder.bind(IDiagramSelectionListener.class).to(IDiagramSelectionListener.NullImpl.class);
		binder.bind(IDiagramExpansionListener.class).to(IDiagramExpansionListener.NullImpl.class);
		binder.bind(IDiagramOpenListener.class).to(IDiagramOpenListener.NullImpl.class);
		binder.bind(IModelUpdateListener.class).to(IModelUpdateListener.NullImpl.class);
		binder.bind(IPopupModelFactory.class).to(IPopupModelFactory.NullImpl.class);
	}

}
