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

package org.eclipse.sprotty.xtext.tracing

import com.google.inject.Inject
import java.util.Map
import java.util.concurrent.CompletableFuture
import java.util.function.BiFunction
import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EStructuralFeature
import org.eclipse.sprotty.SModelElement
import org.eclipse.sprotty.SModelRoot
import org.eclipse.sprotty.xtext.ILanguageAwareDiagramServer
import org.eclipse.xtext.ide.server.ILanguageServerAccess.Context
import org.eclipse.xtext.ide.server.UriExtensions
import org.eclipse.xtext.resource.ILocationInFileProvider
import org.eclipse.xtext.util.ITextRegion

import static extension org.eclipse.xtext.EcoreUtil2.*

class XtextTraceProvider implements ITraceProvider {
	
	@Inject extension UriExtensions uriExtensions
	@Inject extension ILocationInFileProvider
	@Inject extension PositionConverter
	 
	override trace(SModelElement SModelElement, EObject source) {
		val textRegion = source.getFullTextRegion()
		doTrace(SModelElement, source, textRegion)
	}
	
	override <T extends SModelElement> trace(T SModelElement, EObject source, EStructuralFeature feature, int index) {
		val textRegion = source.getFullTextRegion(feature, index)
		doTrace(SModelElement, source, textRegion)
	}
	
	protected def <T extends SModelElement> T doTrace(T SModelElement, EObject source, ITextRegion textRegion) {
		val range = textRegion.toRange(source)
		val uri = source.normalizedURI.withEmptyAuthority
		val trace = new XtextTrace(uri, range)
		SModelElement.trace = trace.toString()
		SModelElement
	}

	override <T> withSource(SModelElement SModelElement, ILanguageAwareDiagramServer callingServer, BiFunction<EObject, Context, T> readOperation) {
		if (SModelElement.trace !== null) {
			val trace = new XtextTrace(SModelElement.trace)
			val path = uriExtensions.toUriString(trace.elementURI.trimFragment)
			return callingServer.languageServerExtension.languageServerAccess.doRead(path) [ context |
				val element = context.resource.resourceSet.getEObject(trace.elementURI, true)
				return readOperation.apply(element, context)
			]
		}
		return CompletableFuture.completedFuture(null)
	}
	
	override SModelElement findSModelElement(SModelRoot root, EObject element) {
		val containerChain = newArrayList
		var currentContainer = element
		while(currentContainer !== null) {
			containerChain.add(currentContainer)
			currentContainer = currentContainer.eContainer
		} 
		val uri2container = containerChain.toMap[normalizedURI.withEmptyAuthority]
		val results = newHashMap
		doFindSModelElement(root, uri2container) [
			results.put($0, $1)
		]
		if(results.empty)
			return null
		else
		 	return results.entrySet.minBy[containerChain.indexOf(key)].value
	}
	
	protected def void doFindSModelElement(SModelElement element, Map<URI, EObject> uri2container, (EObject, SModelElement)=>void result) {
		if (element.trace !== null) {
			val trace = new XtextTrace(element.trace)
			val candidate = uri2container.get(trace.elementURI)
			if(candidate !== null)
				result.apply(candidate, element)
		}
		element.children?.forEach [
			doFindSModelElement(uri2container, result)
		]
	}
}