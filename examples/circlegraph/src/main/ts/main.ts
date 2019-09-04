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

import "reflect-metadata";

import createContainer from './di.config';
import {
    TYPES, IActionDispatcher, WebSocketDiagramServer, RequestModelAction, FitToScreenAction,
    LayoutAction, SelectAllAction
} from 'sprotty';

import './circlegraph.css';
import 'sprotty/css/sprotty.css';
import 'bootstrap/dist/css/bootstrap.min.css';

const container = createContainer();

const server = container.get<WebSocketDiagramServer>(TYPES.ModelSource);
const websocket = new WebSocket('ws://localhost:8080/circlegraph');
server.listen(websocket);

const dispatcher = container.get<IActionDispatcher>(TYPES.IActionDispatcher);
websocket.addEventListener('open', async () => {
    const setModel = await dispatcher.request(RequestModelAction.create());
    await dispatcher.dispatch(setModel);
    await dispatcher.dispatch(new FitToScreenAction([]));
}, { once: true });

document.getElementById('layoutAll')!.addEventListener('click', () => {
    dispatcher.dispatch(new SelectAllAction(false));
    dispatcher.dispatch(new LayoutAction());
    focusGraph();
});

document.getElementById('layoutSelection')!.addEventListener('click', () => {
    dispatcher.dispatch({ kind: 'layoutSelection' });
    focusGraph();
});

function focusGraph(): void {
    const graphElement = document.getElementById('sprotty_graph');
    if (graphElement !== null && typeof graphElement.focus === 'function')
        graphElement.focus();
}
