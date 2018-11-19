/**
 * Classes that extend the an Xtext-based language server to provide Sprotty diagrams.
 * 
 * All classes in this package are instantiated by the same injector as 
 * the language server. Injecting them into classes from the language specific
 * context results in an DI error.
 */
package org.eclipse.sprotty.xtext.ls;