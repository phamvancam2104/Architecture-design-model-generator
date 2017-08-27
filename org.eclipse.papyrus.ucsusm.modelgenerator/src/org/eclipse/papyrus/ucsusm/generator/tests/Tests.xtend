package org.eclipse.papyrus.ucsusm.generator.tests

import org.junit.Test
import org.eclipse.papyrus.ucsusm.generator.ModelGenerator
import org.eclipse.core.resources.ResourcesPlugin

class Tests {
	@Test
	def generateModel() {
		var generator = new ModelGenerator
		var pj = ResourcesPlugin.workspace.root.getProject("GeneratedModels")
		if (!pj.exists) {
			pj.create(null)
			pj.open(null)
		}
		generator.generateModels(1, pj, "generatedmodels")
	}
	
}