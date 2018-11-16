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
 
package org.eclipse.sprotty.xtext

import com.google.inject.Inject
import com.google.inject.Provider
import java.util.List
import org.eclipse.sprotty.IDiagramServer

/**
 * Responsible for creating diagram servers for an Xtext language.
 */
interface IDiagramServerFactory {
	
	def List<String> getDiagramTypes()
	
	def IDiagramServer createDiagramServer(String diagramType, String clientId)
}

abstract class DiagramServerFactory implements IDiagramServerFactory {
	
	@Inject Provider<IDiagramServer> diagramServerProvider
	
	/**
	 * Create a new diagram server with the given clientId.
	 */
	override createDiagramServer(String diagramType, String clientId) {
		val server = diagramServerProvider.get
		server.clientId = clientId
		if (server instanceof LanguageAwareDiagramServer) {
			server.diagramType = diagramType			
		}
		return server
	}
}