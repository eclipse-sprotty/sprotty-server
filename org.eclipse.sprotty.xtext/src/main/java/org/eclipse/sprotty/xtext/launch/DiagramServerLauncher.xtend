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

import com.google.common.io.ByteStreams
import com.google.inject.Guice
import com.google.inject.Inject
import java.io.ByteArrayInputStream
import java.io.FileOutputStream
import java.io.InputStream
import java.io.OutputStream
import java.io.PrintStream
import java.io.PrintWriter
import java.util.concurrent.Executors
import java.util.function.Function
import org.apache.log4j.AppenderSkeleton
import org.apache.log4j.AsyncAppender
import org.apache.log4j.Level
import org.apache.log4j.Logger
import org.apache.log4j.spi.LoggingEvent
import org.eclipse.lsp4j.MessageParams
import org.eclipse.lsp4j.MessageType
import org.eclipse.lsp4j.jsonrpc.Launcher
import org.eclipse.lsp4j.jsonrpc.MessageConsumer
import org.eclipse.lsp4j.jsonrpc.validation.ReflectiveMessageValidator
import org.eclipse.lsp4j.services.LanguageClient
import org.eclipse.xtend.lib.annotations.Data
import org.eclipse.xtext.ide.server.LanguageServerImpl
import org.eclipse.xtext.ide.server.LaunchArgs
import org.eclipse.xtext.ide.server.ServerLauncher

abstract class DiagramServerLauncher extends ServerLauncher {
	
	public static val LOG = '-log'
	public static val TRACE = '-trace'
	public static val NO_VALIDATE = '-noValidate'

	@Inject protected LanguageServerImpl languageServer

	DiagramLanguageServerSetup setup
	
	def abstract DiagramLanguageServerSetup createSetup()

	def void run(String... args) {
		setup = createSetup
		setup.setupLanguages
		
		val prefix = class.name
		val launchArgs = ServerLauncher.createLaunchArgs(prefix, args)
    	val injector = Guice.createInjector(setup.languageServerModule)
    	injector.injectMembers(this)
    	start(launchArgs);
	}
	
	def createLauncher(LaunchArgs it) {
		val executorService = Executors.newCachedThreadPool
		Launcher.createIoLauncher(languageServer, setup.languageClientClass, in, out, executorService,
				wrapper, [setup.configureGson(it)])
	}

	override start(LaunchArgs args) {
		val launcher = createLauncher(args)
		val client = launcher.remoteProxy
		languageServer.connect(client)
		// Redirect Log4J output to client
		Logger.rootLogger => [
			removeAllAppenders()
			addAppender(new AsyncAppender() => [
				addAppender(new LanguageClientAppender(client))
			])
		]
		val future = launcher.startListening
		while (!future.done) {
			Thread.sleep(10_000l)
		}
	}

	private def Function<MessageConsumer, MessageConsumer> getWrapper(LaunchArgs args) {
		[ consumer |
			var result = consumer
			if (args.trace !== null) {
				result = [ message |
					args.trace.println(message)
					args.trace.flush()
					consumer.consume(message)
				]
			}
			if (args.validate) {
				result = new ReflectiveMessageValidator(result)
			}
			return result
		]
	}
	
	@Data static class LanguageClientAppender extends AppenderSkeleton {
		LanguageClient client
		
		override protected append(LoggingEvent event) {
			client.logMessage(new MessageParams => [
				message = event.message?.toString 
					+ if (event.throwableStrRep !== null && event.throwableStrRep.length > 0) 
						': ' + event.throwableStrRep?.join('\n')
					  else 
					    ''
				type = switch event.getLevel {
					case Level.ERROR: MessageType.Error
					case Level.INFO : MessageType.Info
					case Level.WARN : MessageType.Warning
					default : MessageType.Log
				}
			])
		}
		
		override close() {
		}
		
		override requiresLayout() {
			return false
		}
	}
	

	def static LaunchArgs createLaunchArgs(String prefix, String[] args) {
		val launchArgs = new LaunchArgs
		launchArgs.in = System.in
		launchArgs.out = System.out
		redirectStandardStreams(prefix, args)
		launchArgs.trace = args.trace
		launchArgs.validate = args.shouldValidate
		return launchArgs
	}

	def static PrintWriter getTrace(String[] args) {
		if (shouldTrace(args))
			return createTrace
	}

	def static PrintWriter createTrace() {
		return new PrintWriter(System.out)
	}

	def static redirectStandardStreams(String prefix, String[] args) {
		if (shouldLogStandardStreams(args)) {
			logStandardStreams(prefix)
		} else {
			silentStandardStreams
		}
	}

	def static boolean shouldValidate(String[] args) {
		return !args.testArg(NO_VALIDATE)
	}

	def static boolean shouldTrace(String[] args) {
		return args.testArg(TRACE)
	}

	def static boolean shouldLogStandardStreams(String[] args) {
		return args.testArg(ServerLauncher.LOG, 'debug')
	}

	def static boolean testArg(String[] args, String ... values) {
		return args.exists[arg|arg.testArg(values)]
	}

	def static boolean testArg(String arg, String ... values) {
		return values.exists[value|value == arg]
	}

	def static void logStandardStreams(String prefix) {
		val stdFileOut = new FileOutputStream(prefix + "-debug.log")
		redirectStandardStreams(stdFileOut)
	}

	def static void silentStandardStreams() {
		redirectStandardStreams(ServerLauncher.silentOut)
	}

	def static void redirectStandardStreams(OutputStream out) {
		redirectStandardStreams(ServerLauncher.silentIn, out)
	}

	def static void redirectStandardStreams(InputStream in, OutputStream out) {
		System.setIn(in)
		System.setOut(new PrintStream(out))
	}

	def static OutputStream silentOut() {
		ByteStreams.nullOutputStream
	}

	def static InputStream silentIn() {
		new ByteArrayInputStream(newByteArrayOfSize(0))
	}
}
