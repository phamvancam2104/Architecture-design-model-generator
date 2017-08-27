package org.eclipse.papyrus.ucsusm.generator

import org.eclipse.uml2.uml.Port

class PartPort {
	public org.eclipse.uml2.uml.Property part;
	public Port port
	public new(org.eclipse.uml2.uml.Property part, Port port) {
		this.part = part
		this.port = port
	}
}