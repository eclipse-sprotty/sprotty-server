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

import com.google.inject.Inject
import com.google.inject.Singleton
import java.util.Collection
import java.util.List
import java.util.Set
import java.util.Timer
import java.util.TimerTask
import java.util.concurrent.CompletableFuture
import java.util.concurrent.LinkedBlockingQueue
import org.apache.log4j.Logger
import org.eclipse.emf.common.util.URI
import org.eclipse.sprotty.Action
import org.eclipse.sprotty.xtext.ILanguageAwareDiagramServer
import org.eclipse.sprotty.xtext.LanguageAwareDiagramServer
import org.eclipse.xtend.lib.annotations.Accessors
import org.eclipse.xtext.ide.server.ILanguageServerAccess
import org.eclipse.xtext.ide.server.UriExtensions
import org.eclipse.xtext.resource.IResourceServiceProvider
import org.eclipse.xtext.validation.CheckMode
import org.eclipse.xtext.validation.IResourceValidator

@Singleton
class DiagramUpdater {
	
	static final Logger LOG = Logger.getLogger(DiagramUpdater)

	@Accessors(PROTECTED_GETTER)
	DiagramLanguageServer languageServer

	@Inject
	@Accessors(PROTECTED_GETTER)
	IResourceServiceProvider.Registry resourceServiceProviderRegistry

	@Inject extension UriExtensions

	DeferredDiagramUpdater updater

	def void initialize(DiagramLanguageServer languageServer) {
		this.languageServer = languageServer
		updater = new DeferredDiagramUpdater([it | doUpdateDiagrams(it)])
		languageServer.languageServerAccess.addBuildListener [ deltas |
			updateDiagrams(deltas.map[uri].toSet)
		]
	}

	def void updateDiagram(LanguageAwareDiagramServer diagramServer) {
		updateDiagram(diagramServer, null)
	}

	def CompletableFuture<Void> updateDiagram(LanguageAwareDiagramServer diagramServer, Action cause) {
		val uri = diagramServer.sourceUri
		if (uri.isNullOrEmpty) {
			val exc = new RuntimeException("Missing property 'sourceUri'.")
			diagramServer.rejectRemoteRequest(cause, exc)
			LOG.error("Failed to update diagram.", exc);
			return CompletableFuture.completedFuture(null);
		}
		languageServer.languageServerAccess.doRead(diagramServer.sourceUri) [ context |
			try {
				val issueProvider = validate(context)
				val root = diagramServer.generate(context, issueProvider)
				if (root === null)
					diagramServer.rejectRemoteRequest(cause, new RuntimeException("Could not generate model for URI " + diagramServer.sourceUri))
				else
					diagramServer.updateModel(root, cause)
			} catch (Exception exc) {
				diagramServer.rejectRemoteRequest(cause, exc)
				LOG.error("Exception while updating diagram for URI " + diagramServer.sourceUri, exc);
			}
			null
		]
	}

	/**
	 * Update the diagrams for the given URIs using the configured diagram generator.
	 */
	protected def void updateDiagrams(Collection<? extends URI> uris) {
		updater.updateLater(uris)
	}

	protected def CompletableFuture<Void> doUpdateDiagrams(Collection<? extends URI> uris) {
		val futures = newArrayList
		for (uri : uris) {
			val path = uri.toUriString
			val diagramServers = languageServer.diagramServerManager.findDiagramServersByUri(path)
			if (!diagramServers.empty) {
				futures += doUpdateDiagrams(path, diagramServers)
			}
		}
		if (futures.empty)
			return CompletableFuture.completedFuture(null)
		else
			return CompletableFuture.allOf(futures)
	}

	protected def CompletableFuture<Void> doUpdateDiagrams(String path, List<? extends ILanguageAwareDiagramServer> diagramServers) {
		languageServer.languageServerAccess.doRead(path) [ context |
			val issueProvider = validate(context)
			diagramServers.forEach [
				val root = generate(context, issueProvider)
				if (root !== null)
					updateModel(root)
			]
			null
		]
	}

	protected def IssueProvider validate(ILanguageServerAccess.Context context) {
		if (context.resource === null)
			return null
		val issues = resourceServiceProviderRegistry
			.getResourceServiceProvider(context.resource.URI)
			?.get(IResourceValidator)
			?.validate(context.resource, CheckMode.NORMAL_AND_FAST, context.cancelChecker)
		new IssueProvider(issues ?: emptyList)
	}
}

class DeferredDiagramUpdater {

	Timer currentTimer

	val uris = new LinkedBlockingQueue<URI>

	val lock = new Object

	val (Set<? extends URI>)=>void updateFunction

	new((Set<? extends URI>)=>void updateFunction) {
		this.updateFunction = updateFunction
	}

	def void updateLater(Collection<? extends URI> newUris) {
		uris.addAll(newUris)
		schedule(200)
	}

	protected def void schedule(long delay) {
		synchronized(lock) {
			if(currentTimer !== null)
				currentTimer.cancel
			currentTimer = new Timer('Diagram updater', true)
			currentTimer.schedule(createTimerTask, delay)
		}
	}

	protected def TimerTask createTimerTask() {
		[ this.update() ]
	}

	protected def void update() {
		val processUris = <URI>newHashSet
		uris.drainTo(processUris)
		updateFunction.apply(processUris)
	}
}