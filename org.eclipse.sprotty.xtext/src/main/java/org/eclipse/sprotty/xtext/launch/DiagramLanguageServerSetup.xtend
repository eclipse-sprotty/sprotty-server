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
 
package org.eclipse.sprotty.xtext.launch

import com.google.gson.GsonBuilder
import com.google.inject.Module
import org.eclipse.lsp4j.services.LanguageClient
import org.eclipse.sprotty.server.json.ActionTypeAdapter
import org.eclipse.sprotty.server.json.EnumTypeAdapter
import org.eclipse.sprotty.xtext.ls.DiagramServerModule
import org.eclipse.xtext.ide.server.ServerModule
import org.eclipse.xtext.util.Modules2

abstract class DiagramLanguageServerSetup {
	
	def void setupLanguages()
	
	def GsonBuilder configureGson(GsonBuilder gsonBuilder) {
		val factory = new ActionTypeAdapter.Factory()
		gsonBuilder
			.registerTypeAdapterFactory(factory)
			.registerTypeAdapterFactory(new EnumTypeAdapter.Factory())
	}
	
	def Module getLanguageServerModule() {
		Modules2.mixin(
			new ServerModule,
			// use SyncDiagramServerModule to sync the selection of text editors and diagrams
			new DiagramServerModule
		) 
	}
	
	def Class<? extends LanguageClient> getLanguageClientClass() {
		return LanguageClient
	}

}
