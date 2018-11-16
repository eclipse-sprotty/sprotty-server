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

import com.google.common.collect.HashMultimap
import com.google.inject.Inject
import com.google.inject.Singleton
import java.util.Collection
import java.util.List
import java.util.Map
import org.eclipse.sprotty.IDiagramServer
import org.eclipse.sprotty.xtext.IDiagramServerFactory
import org.eclipse.sprotty.xtext.ILanguageAwareDiagramServer
import org.eclipse.sprotty.xtext.LanguageAwareDiagramServer
import org.eclipse.xtend.lib.annotations.Data
import org.eclipse.xtext.resource.IResourceServiceProvider
import org.eclipse.xtext.util.internal.Log

@Log
@Singleton
class DiagramServerManager {

	// injecting this yields a ProvisionException
	DiagramLanguageServer languageServer

	@Inject extension IResourceServiceProvider.Registry languagesRegistry

	Map<String, IDiagramServer> clientId2diagramServer = newLinkedHashMap
	
	List<IDiagramServerFactory> diagramServerFactories 

	def void initialize(DiagramLanguageServer languageServer) {
		this.languageServer = languageServer
	}

	def List<? extends ILanguageAwareDiagramServer> findDiagramServersByUri(String uri) {
		synchronized (clientId2diagramServer)
			clientId2diagramServer.values.filter(ILanguageAwareDiagramServer).filter[sourceUri == uri].toList
	}

	def IDiagramServer getDiagramServer(String diagramType, String clientId) {
		synchronized (clientId2diagramServer) {
			val existingDiagramServer = clientId2diagramServer.get(clientId)
			if (existingDiagramServer !== null) {
				return existingDiagramServer
			} else {
				val diagramService = getDiagramServerFactory(diagramType)
				if (diagramService === null) {
					LOG.error("No diagram service for type '" + diagramType + "'")
					return null					
				}
				val newDiagramServer = diagramService.createDiagramServer(diagramType, clientId)
				if (newDiagramServer instanceof LanguageAwareDiagramServer)
					newDiagramServer.diagramLanguageServer = languageServer
				newDiagramServer.remoteEndpoint = [ message |
					languageServer.client?.accept(message)
				]
				clientId2diagramServer.put(clientId, newDiagramServer)
				return newDiagramServer
			}
		}
	}
	
	def void removeDiagramServer(String clientId) {
		synchronized (clientId2diagramServer)
			clientId2diagramServer.remove(clientId)
	}
	
	def Collection<? extends IDiagramServer> getDiagramServers() {
		clientId2diagramServer.values
	}
	
	@Data
	protected static class Key {
		String clientId
		String diagramType
	}
	
	protected def Iterable<? extends IDiagramServerFactory> getDiagramServerFactories() {
		if (diagramServerFactories === null) {
			val resourceServiceProviders = languagesRegistry
				.extensionToFactoryMap
				.values
				.filter(IResourceServiceProvider)
				.toSet
			diagramServerFactories = resourceServiceProviders
				.map[get(IDiagramServerFactory)]
				.filterNull
				.toList
			val serviceByType = HashMultimap.<String, IDiagramServerFactory>create
			diagramServerFactories.forEach [ factory |
				factory.diagramTypes.forEach [
					serviceByType.put(it, factory)
				]
			]
			serviceByType.keySet.forEach [ diagramType |
				val servicesWithSameType = serviceByType.get(diagramType)
				if (servicesWithSameType.length > 1) {
					LOG.error('''Multiple diagram services with diagram type '«
							diagramType
						»': «
							servicesWithSameType.map[class.simpleName].join(', ')
						». Ignoring all but «
							servicesWithSameType.head.class.simpleName
						»'''
					)
					diagramServerFactories.removeAll(servicesWithSameType.tail)
				}
			]
		}
		diagramServerFactories
	}
	
	protected def getDiagramServerFactory(String diagramType) {
		if (diagramType === null) {
			if(getDiagramServerFactories.size !== 1)  
				LOG.error('Cannot choose default from multiple diagram types: ' 
					+ getDiagramServerFactories.map[diagramTypes].flatten.join(', '))
		 	return getDiagramServerFactories.head
		}
		getDiagramServerFactories.findFirst[diagramTypes.contains(diagramType)]
	}
}
