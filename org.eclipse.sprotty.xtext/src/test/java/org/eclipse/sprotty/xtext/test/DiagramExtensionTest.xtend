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

package org.eclipse.sprotty.xtext.test

import com.google.inject.Inject
import org.eclipse.sprotty.DiagramOptions
import org.eclipse.sprotty.RequestModelAction
import org.eclipse.sprotty.xtext.ls.DiagramServerManager
import org.eclipse.sprotty.xtext.testlanguage.diagram.TestDiagramServerFactory
import org.junit.Test

import static org.junit.Assert.*

class DiagramExtensionTest extends AbstractDiagramServerTest {
	
	@Inject DiagramServerManager diagramServerManager
	
    @Test
    def void testCloseDiagram() {
        val sourceUri = writeFile('graph.testlang', '''
            node foo
            node bar
        ''')
    	initialize()
    	action(new RequestModelAction [
    		options = #{
    			DiagramOptions.OPTION_DIAGRAM_TYPE -> TestDiagramServerFactory.DIAGRAM_TYPE,
    			DiagramOptions.OPTION_SOURCE_URI -> sourceUri
    			
    		}
    	])
    	assertEquals(1, diagramServerManager.diagramServers.size)
    	closeDiagram()
    	assertEquals(0, diagramServerManager.diagramServers.size)
    }
	
}