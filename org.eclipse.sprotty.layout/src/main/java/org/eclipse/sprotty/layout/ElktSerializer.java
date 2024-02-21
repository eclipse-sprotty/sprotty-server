/********************************************************************************
 * Copyright (c) 2019 TypeFox and others.
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
package org.eclipse.sprotty.layout;

import java.io.ByteArrayOutputStream;
import java.lang.reflect.Method;
import java.nio.charset.Charset;

import jakarta.inject.Inject;
import jakarta.inject.Provider;

import org.apache.log4j.Logger;
import org.eclipse.elk.graph.ElkNode;
import org.eclipse.emf.common.util.URI;
import org.eclipse.emf.ecore.resource.Resource;
import org.eclipse.emf.ecore.resource.impl.ResourceSetImpl;


/**
 * Allows to dump an ELK model in ELKT, such that it can be debugged in
 * https://rtsys.informatik.uni-kiel.de/elklive/elkgraph.html
 *
 * This class needs the Maven artifact
 *   groupID: org.eclipse.elk
 *   artifactId: org.eclipse.elk.graph.text
 * on the classpath.
 */
public class ElktSerializer {

	private static final Logger LOG = Logger.getLogger(ElktSerializer.class);

	protected Provider<ResourceSetImpl> resourceSetProvider;

	@Inject
	public void setResourceSetProvider(Provider<ResourceSetImpl> resourceSetProvider) {
		this.resourceSetProvider = resourceSetProvider;
	}

	/**
	 * Serlialize the given ELK model to ELKT
	 */
	public String toElkt(ElkNode node) {
		try (ByteArrayOutputStream baos = new ByteArrayOutputStream(32768)) {
			registerElkt();
			Resource resource = resourceSetProvider.get().createResource(URI.createURI("dump.elkt"));
			resource.getContents().add(node);
			resource.save(baos, null);
			String text = new String(baos.toByteArray(), Charset.defaultCharset());
			return text;
		} catch (Throwable exc) {
			LOG.error("Error serializing ELK model", exc);
		}
		return null;
	}

	/**
	 * Makes sure ELKT is registered to the EMF registries.
	 */
	protected void registerElkt() throws Exception {
		Object factory = Resource.Factory.Registry.INSTANCE.getExtensionToFactoryMap().get("elkt");
		if (factory == null) {
			Class<?> standaloneSetupClass = Class.forName("org.eclipse.elk.graph.text.ElkGraphStandaloneSetup");
			if (standaloneSetupClass == null)
				throw new IllegalStateException("'ElkGraphStandaloneSetup' is not on the classpath. Add 'org.eclipse.elk:org.eclipse.elk.graph.text' to your classpath.");
			Method doSetupMethod = standaloneSetupClass.getMethod("doSetup");
			doSetupMethod.invoke(null);
		}
	}
}