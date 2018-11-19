/********************************************************************************
 * Copyright (c) 2018 TypeFox and others.
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
 
package org.eclipse.sprotty.xtext.ls

import org.eclipse.lsp4j.Location
import org.eclipse.lsp4j.jsonrpc.services.JsonNotification
import org.eclipse.lsp4j.jsonrpc.services.JsonSegment
import org.eclipse.xtend.lib.annotations.Data

/**
 * A diagram language server that connects to a client that supports 
 * opening a text editor at a given location. 
 * 
 * This allows to synchronize the selection between diagram views and
 * text editors.
 * 
 * @see SyncDiagramClient
 */
class SyncDiagramLanguageServer extends DiagramLanguageServer {
	
	override protected getClientInterface() {
		SyncDiagramClient
	}
}

class SyncDiagramServerModule extends DiagramServerModule {
	
	override bindLanguageServerImpl() {
		SyncDiagramLanguageServer
	}
}

@JsonSegment('diagram')
interface SyncDiagramClient extends DiagramEndpoint {
	
	@JsonNotification
	def void openInTextEditor(OpenInTextEditorMessage message)
	
}

@Data
class OpenInTextEditorMessage {
	Location location
	boolean forceOpen
}
