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

package org.eclipse.sprotty.xtext.tracing

import org.eclipse.sprotty.SModelRoot
import org.eclipse.sprotty.xtext.ILanguageAwareDiagramServer
import java.util.concurrent.CompletableFuture
import java.util.function.BiFunction
import org.eclipse.emf.ecore.EObject
import org.eclipse.xtext.ide.server.ILanguageServerAccess.Context
import org.eclipse.sprotty.Traceable
import org.eclipse.sprotty.SModelElement
import org.eclipse.emf.ecore.EStructuralFeature

interface ITraceProvider {

	def <T extends Traceable> T trace(T traceable, EObject source)

	def <T extends Traceable> T trace(T traceable, EObject source, EStructuralFeature feature, int index)
	
	def <T> CompletableFuture<T> withSource(Traceable traceable, ILanguageAwareDiagramServer languageServer, BiFunction<EObject, Context, T> readOperation)
	
	def SModelElement findTraceable(SModelRoot root, EObject element) 
}