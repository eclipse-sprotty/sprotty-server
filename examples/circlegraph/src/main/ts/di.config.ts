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
    defaultModule, TYPES, configureViewerOptions, SGraphView, PolylineEdgeView, ConsoleLogger,
    LogLevel, WebSocketDiagramServer, boundsModule, moveModule, selectModule, undoRedoModule, viewportModule,
    exportModule, CircularNode, configureModelElement, SGraph, SEdge, ActionHandlerRegistry,
    LayoutAction, SelectionResult, ViewportResult, updateModule, graphModule, routingModule,
    modelSourceModule, selectFeature, moveFeature, createRandomId
} from 'sprotty';
import { CircleNodeView } from './views';

class CustomNode extends CircularNode {
    hasFeature(feature: symbol): boolean {
        if (feature === moveFeature)
            return false;
        else
            return super.hasFeature(feature);
    }
}

class CustomEdge extends SEdge {
    hasFeature(feature: symbol): boolean {
        if (feature === selectFeature)
            return false;
        else
            return super.hasFeature(feature);
    }
}

class CircleGraphDiagramServer extends WebSocketDiagramServer {
    initialize(registry: ActionHandlerRegistry): void {
        super.initialize(registry);
        registry.register(LayoutAction.KIND, this);
        registry.register(SelectionResult.KIND, this);
        registry.register(ViewportResult.KIND, this);
        registry.register('layoutSelection', this);

        this.clientId = createRandomId(16);
    }
}

export default () => {
    const circleGraphModule = new ContainerModule((bind, unbind, isBound, rebind) => {
        bind(TYPES.ModelSource).to(CircleGraphDiagramServer).inSingletonScope();
        rebind(TYPES.ILogger).to(ConsoleLogger).inSingletonScope();
        rebind(TYPES.LogLevel).toConstantValue(LogLevel.warn);
        const context = { bind, unbind, isBound, rebind };
        configureModelElement(context, 'graph', SGraph, SGraphView);
        configureModelElement(context, 'node', CustomNode, CircleNodeView);
        configureModelElement(context, 'edge', CustomEdge, PolylineEdgeView);
        configureViewerOptions(context, {
            needsClientLayout: false,
            needsServerLayout: true
        });
    });

    const container = new Container();
    container.load(defaultModule, selectModule, moveModule, boundsModule, undoRedoModule, viewportModule,
        exportModule, updateModule, graphModule, routingModule, modelSourceModule, circleGraphModule);
    return container;
};
