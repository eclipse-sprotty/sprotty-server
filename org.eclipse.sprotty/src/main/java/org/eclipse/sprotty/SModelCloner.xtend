package org.eclipse.sprotty

import java.lang.reflect.Modifier
import java.util.List

/**
 * Makes a deep copy of an {@link SModelElement}. 
 * 
 * <p>
 * This is not a general object cloner, as it assumes e.g. that
 * <ul>
 * <li>element classes have a default constructor,</li>
 * <li>there are no map/set-valued fields,</li>
 * <li>there are no cross references, i.e. the element and it's fields form a tree.</li>
 * </ul>
 * </p>
 */
class SModelCloner {
	
	def SModelRoot clone(SModelRoot root) {
		val clone = root.doClone
		return clone as SModelRoot
	}
	
	protected def dispatch Object doClone(Object obj) {
		val clone = obj.class.newInstance()
		var Class<?> currentClass = obj.class
		do {
			for (field : currentClass.declaredFields) {
				field.accessible = true
				if (field.get(obj) !== null && !Modifier.isFinal(field.modifiers)) {
					if (field.type.primitive) 
						field.set(clone, field.get(obj))
					else
						field.set(clone, field.get(obj).doClone)
				}
			}
			currentClass = currentClass.superclass
		} while (currentClass != Object && currentClass !== null)
		return clone
	}
	
	protected def dispatch List<?> doClone(List<?> c) {
		val clone = newArrayList
		for (var i = c.iterator; i.hasNext; ) 
			clone.add(i.next.doClone)
		return clone
	}
	
	protected def dispatch String doClone(String s) {
		s
	}
	
	protected def dispatch Boolean doClone(Boolean b) {
		b
	}
	
	protected def dispatch Number doClone(Number n) {
		n
	}
}
