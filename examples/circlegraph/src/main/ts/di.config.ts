/********************************************************************************
 * Copyright (c) 2017-2019 TypeFox and others.
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

import { Container, ContainerModule } from 'inversify';
import {
    TYPES, configureViewerOptions, SGraphView, PolylineEdgeView, ConsoleLogger, LogLevel,
    WebSocketDiagramServer, CircularNode, configureModelElement, SGraph, SEdge, LayoutAction,
    SelectionResult, ViewportResult, selectFeature, moveFeature, loadDefaultModules,
    configureActionHandler
} from 'sprotty';
import { CircleNodeView } from './views';

export default () => {
    const circleGraphModule = new ContainerModule((bind, unbind, isBound, rebind) => {
        bind(TYPES.ModelSource).to(WebSocketDiagramServer).inSingletonScope();
        rebind(TYPES.ILogger).to(ConsoleLogger).inSingletonScope();
        rebind(TYPES.LogLevel).toConstantValue(LogLevel.warn);

        const context = { bind, unbind, isBound, rebind };
        configureModelElement(context, 'graph', SGraph, SGraphView);
        configureModelElement(context, 'node', CircularNode, CircleNodeView, {
            disable: [moveFeature]
        });
        configureModelElement(context, 'edge', SEdge, PolylineEdgeView, {
            disable: [selectFeature]
        });
        configureActionHandler(context, LayoutAction.KIND, TYPES.ModelSource);
        configureActionHandler(context, SelectionResult.KIND, TYPES.ModelSource);
        configureActionHandler(context, ViewportResult.KIND, TYPES.ModelSource);
        configureActionHandler(context, 'layoutSelection', TYPES.ModelSource);
        configureViewerOptions(context, {
            needsClientLayout: false,
            needsServerLayout: true
        });
    });

    const container = new Container();
    loadDefaultModules(container);
    container.load(circleGraphModule);
    return container;
};
