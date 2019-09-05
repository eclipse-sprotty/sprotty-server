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

import org.eclipse.sprotty.Action;
import org.eclipse.sprotty.DefaultDiagramServer;
import org.eclipse.sprotty.FitToScreenAction;
import org.eclipse.sprotty.GetSelectionAction;
import org.eclipse.sprotty.SGraph;
import org.eclipse.sprotty.UpdateModelAction;

public class CircleGraphDiagramServer extends DefaultDiagramServer {
	
	@Override
	protected void handleAction(Action action) {
		switch (action.getKind()) {
			case LayoutSelectionAction.KIND:
				handle((LayoutSelectionAction) action);
				break;
			default:
				super.handleAction(action);
		}
	}
	
	protected void handle(LayoutSelectionAction action) {
		request(new GetSelectionAction()).thenAccept(selection -> {
			SGraph model = (SGraph) getModel();
			GraphLayoutEngine layoutEngine = (GraphLayoutEngine) getLayoutEngine();
			layoutEngine.setSelection(selection.getSelectedElementsIDs());
			layoutEngine.layout(model, action);
			dispatch(new UpdateModelAction(model));
			dispatch(new FitToScreenAction(fitToScreen -> {
				fitToScreen.setMaxZoom(1.0);
				fitToScreen.setPadding(20.0);
				fitToScreen.setElementIds(selection.getSelectedElementsIDs());
			}));
			layoutEngine.clearSelection();
		});
	}

}
