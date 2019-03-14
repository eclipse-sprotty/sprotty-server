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

import com.google.inject.Guice
import java.net.InetSocketAddress
import java.nio.channels.AsynchronousServerSocketChannel
import java.nio.channels.Channels
import java.util.concurrent.Executors
import org.apache.log4j.Logger
import org.eclipse.lsp4j.jsonrpc.Launcher
import org.eclipse.xtext.ide.server.LanguageServerImpl

abstract class DiagramServerSocketLauncher {

	static val LOG = Logger.getLogger(DiagramServerSocketLauncher)

	public static val int DEFAULT_PORT = 5008

	def run(String... args) {
		try {
			val setup = createSetup()
			setup.setupLanguages

			val injector = Guice.createInjector(setup.languageServerModule)
			val serverSocket = AsynchronousServerSocketChannel.open.bind(new InetSocketAddress("0.0.0.0", getPort(args)))

			while (true) {
				val socketChannel = serverSocket.accept.get
				val in = Channels.newInputStream(socketChannel)
				val out = Channels.newOutputStream(socketChannel)
				val languageServer = injector.getInstance(LanguageServerImpl)
				val executorService = Executors.newCachedThreadPool
				val launcher = Launcher.createIoLauncher(
					languageServer, setup.languageClientClass,
					in, out, executorService,
					[it], [setup.configureGson(it)])
				languageServer.connect(launcher.remoteProxy)
				launcher.startListening
				LOG.info("Started language server for client " + socketChannel.remoteAddress)
			}
		} catch (Throwable throwable) {
			throwable.printStackTrace()
		}
	}

	protected def getPort(String... args) {
		for(var i = 0; i < args.length - 1; i++) {
			if (args.get(i) == '--port')
				return Integer.parseInt(args.get(i+1))
		}
		return DEFAULT_PORT
	}

	def abstract DiagramLanguageServerSetup createSetup()

}
