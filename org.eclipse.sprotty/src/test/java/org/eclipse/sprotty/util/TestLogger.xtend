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
package org.eclipse.sprotty.util

import java.util.List
import org.apache.log4j.Appender
import org.apache.log4j.Layout
import org.apache.log4j.spi.ErrorHandler
import org.apache.log4j.spi.Filter
import org.apache.log4j.spi.LoggingEvent
import org.eclipse.xtend.lib.annotations.Accessors

@Accessors
class TestLogger implements Appender {
	
	String name
	Layout layout
	Filter filter
	ErrorHandler errorHandler
	
	val List<LoggingEvent> events = newArrayList
	
	override toString() {
		val builder = new StringBuilder
		for (event : events) {
			builder.append(event.getLevel).append(': ').append(event.message)
			if (event.throwableInformation !== null)
				builder.append(' (').append(event.throwableInformation.throwable.class.name).append(')')
			builder.append('\n')
		}
		return builder.toString
	}
	
	def void print() {
		System.out.print(this)
	}
	
	override doAppend(LoggingEvent event) {
		events.add(event)
	}
	
	def void reset() {
		events.clear()
	}
	
	override addFilter(Filter newFilter) {
		if (this.filter === null) {
			this.filter = newFilter
		} else {
			var f = this.filter
			while (f.getNext !== null) {
				f = f.getNext
			}
			f.setNext = newFilter
		}
	}
	
	override clearFilters() {
		filter = null
	}
	
	override requiresLayout() {
		false
	}
	
	override close() {
	}
	
}