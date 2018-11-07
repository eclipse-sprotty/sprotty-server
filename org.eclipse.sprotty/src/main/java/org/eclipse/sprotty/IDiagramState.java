/********************************************************************************
 * Copyright (c) 2017-2018 TypeFox and others.
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

package org.eclipse.sprotty;

import java.util.Map;
import java.util.Set;

/**
 * A view on the current state of the diagram.
 * 
 * @author koehnlein
 */
public interface IDiagramState {
	/**
	 * The options received from the client with the last {@link RequestModelAction}. These options
	 * can be used to control diagram creation. If no such action has been received yet, or the action did
	 * not contain any options, an empty map is returned.
	 */
	Map<String, String> getOptions();
	
	/**
	 * @return the identifier of the client attached to this server.
	 */
	String getClientId();
	
	/**
	 * @return the current model
	 */
	SModelRoot getCurrentModel();
	
	/**
	 * @return the IDs of the currently expanded {@link SModelElement}s.
	 */
	Set<String> getExpandedElements();

	/**
	 * @return the IDs of the currently selected {@link SModelElement}s.
	 */
	Set<String> getSelectedElements();
	
}