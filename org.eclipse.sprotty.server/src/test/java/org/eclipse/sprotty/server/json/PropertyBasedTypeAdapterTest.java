/********************************************************************************
 * Copyright (c) 2020 TypeFox and others.
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
package org.eclipse.sprotty.server.json;

import org.junit.Test;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import com.google.gson.TypeAdapter;
import com.google.gson.TypeAdapterFactory;
import com.google.gson.reflect.TypeToken;

import static org.junit.Assert.*;

public class PropertyBasedTypeAdapterTest {
	
	@Test
	public void testParseKnownProperty() {
		Gson gson = createGson();
		TestType t = gson.fromJson("{\"disc\":\"B\",\"valB\":\"foo\"}", TestType.class);
		assertTrue(t instanceof TestTypeB);
		assertEquals("foo", ((TestTypeB) t).valB);
	}
	
	@Test
	public void testParseUnknownProperty() {
		Gson gson = createGson();
		TestType t = gson.fromJson("{\"disc\":\"B\",\"unknown\":\"foo\"}", TestType.class);
		assertTrue(t instanceof TestTypeB);
		assertNull(((TestTypeB) t).valB);
	}
	
	static Gson createGson() {
		return new GsonBuilder()
				.registerTypeAdapterFactory(new TestTypeAdapter.Factory())
				.create();
	}
	
	static class TestTypeAdapter extends PropertyBasedTypeAdapter<TestType> {
		static class Factory implements TypeAdapterFactory {
			@Override
			@SuppressWarnings("unchecked")
			public <T> TypeAdapter<T> create(Gson gson, TypeToken<T> type) {
				if (!TestType.class.equals(type.getRawType()))
					return null;
				return (TypeAdapter<T>) new TestTypeAdapter(gson);
			}
		}
		
		public TestTypeAdapter(Gson gson) {
			super(gson, "disc");
		}

		@Override
		protected TestType createInstance(String parameter) {
			switch (parameter) {
				case "A": return new TestTypeA();
				case "B": return new TestTypeB();
				default: throw new IllegalArgumentException();
			}
		}
	}
	
	interface TestType {}
	static class TestTypeA implements TestType {
		String disc;
		String valA;
	}
	static class TestTypeB implements TestType {
		String disc;
		String valB;
	}

}
