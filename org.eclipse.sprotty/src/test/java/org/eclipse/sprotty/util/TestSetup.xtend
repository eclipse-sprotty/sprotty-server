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
package org.eclipse.sprotty.util

import com.google.inject.Guice
import com.google.inject.Module
import java.util.function.Consumer
import org.eclipse.sprotty.DefaultDiagramServer
import org.eclipse.sprotty.IDiagramExpansionListener
import org.eclipse.sprotty.IDiagramOpenListener
import org.eclipse.sprotty.IDiagramSelectionListener
import org.eclipse.sprotty.IDiagramServer
import org.eclipse.sprotty.ILayoutEngine
import org.eclipse.sprotty.IModelUpdateListener
import org.eclipse.sprotty.IPopupModelFactory
import org.eclipse.xtend.lib.annotations.Accessors
import org.eclipse.xtend.lib.annotations.ToString

@Accessors
@ToString
class TestSetup {
	Class<? extends IModelUpdateListener> modelUpdateListener = IModelUpdateListener.NullImpl
	Class<? extends ILayoutEngine> layoutEngine = ILayoutEngine.NullImpl
	Class<? extends IPopupModelFactory> popupModelFactory = IPopupModelFactory.NullImpl
	Class<? extends IDiagramOpenListener> diagramOpenListener = IDiagramOpenListener.NullImpl
	Class<? extends IDiagramSelectionListener> diagramSelectionListener = IDiagramSelectionListener.NullImpl
	Class<? extends IDiagramExpansionListener> diagramExpansionListener = IDiagramExpansionListener.NullImpl
	
	new() {
	}
	new(Consumer<TestSetup> initializer) {
		initializer.accept(this)
	}
	
	def createInjector() {
		val Module module = [
			bind(IDiagramServer).to(DefaultDiagramServer)
			bind(IModelUpdateListener).to(modelUpdateListener)
			bind(ILayoutEngine).to(layoutEngine)
			bind(IPopupModelFactory).to(popupModelFactory)
			bind(IDiagramOpenListener).to(diagramOpenListener)
			bind(IDiagramSelectionListener).to(diagramSelectionListener)
			bind(IDiagramExpansionListener).to(diagramExpansionListener)
		]
		return Guice.createInjector(module)
	}
	
	def createServer() {
		return createInjector.getInstance(IDiagramServer) as DefaultDiagramServer
	}
}