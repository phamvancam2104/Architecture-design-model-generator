package org.eclipse.papyrus.ucsusm.generator

import org.eclipse.uml2.uml.Port

class PortPair {
	public org.eclipse.uml2.uml.Property aPart
	public Port aPort
	public Port otherPort
	public org.eclipse.uml2.uml.Property otherPart
	public new(org.eclipse.uml2.uml.Property aPart, Port aPort, Port otherPort, org.eclipse.uml2.uml.Property otherPart) {
		this.aPart = aPart
		this.aPort = aPort
		this.otherPort = otherPort
		this.otherPart = otherPart
	}
	
	public static def compare(PortPair th, PortPair other) {
		if (th != null && other != null) {
			return (th.aPart == other.aPart && th.aPort == other.aPort && th.otherPort == other.otherPort && th.otherPart == other.otherPart) ||
			 (th.aPart == other.otherPart && th.aPort == other.otherPort && th.otherPort == other.aPort && th.otherPart == other.aPart)
		 } else if (th == null && other == null) {
		 	return true
		 } else {
		 	return false
		 }
	}
	
	public def isEqual(Port aPort, Port otherPort) {
		return (this.aPort == aPort && this.otherPort == otherPort) || (this.aPort == otherPort && this.otherPort == aPort)
	}
	
}