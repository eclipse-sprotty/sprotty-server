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

import org.eclipse.sprotty.Action
import org.eclipse.sprotty.server.json.ActionTypeAdapter
import java.util.function.Consumer
import org.eclipse.lsp4j.WorkspaceEdit
import org.eclipse.xtend.lib.annotations.Accessors
import org.eclipse.xtend.lib.annotations.EqualsHashCode
import org.eclipse.xtend.lib.annotations.ToString

class EditActionTypeAdapterFactory extends ActionTypeAdapter.Factory {
	
	new() {
		addActionKind(ReconnectAction.KIND, ReconnectAction)
		addActionKind(WorkspaceEditAction.KIND, WorkspaceEditAction)
	}
}

@Accessors
@EqualsHashCode
@ToString(skipNulls = true)
class WorkspaceEditAction implements Action {
	public static val KIND = 'workspaceEdit'
	val kind = KIND	 
	WorkspaceEdit workspaceEdit
	
	new() {}
	new(Consumer<WorkspaceEditAction> initializer) {
		initializer.accept(this)
	}
}

@Accessors
@EqualsHashCode
@ToString(skipNulls = true)
class ReconnectAction implements Action {
    public static val KIND = 'reconnect'

    String routableId
    String newSourceId
    String newTargetId
    String kind = KIND

	new() {}
	new(Consumer<ReconnectAction> initializer) {
		initializer.accept(this)
	}
}
