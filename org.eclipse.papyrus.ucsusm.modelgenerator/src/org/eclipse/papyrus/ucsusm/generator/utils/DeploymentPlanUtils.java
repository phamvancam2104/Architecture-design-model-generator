package org.eclipse.papyrus.ucsusm.generator.utils;

import org.eclipse.papyrus.designer.deployment.tools.DepCreation;
import org.eclipse.papyrus.designer.deployment.tools.DepPlanUtils;
import org.eclipse.papyrus.designer.deployment.tools.DeployConstants;
import org.eclipse.papyrus.designer.transformation.base.utils.TransformationException;
import org.eclipse.uml2.uml.Class;
import org.eclipse.uml2.uml.InstanceSpecification;
import org.eclipse.uml2.uml.Package;

public class DeploymentPlanUtils {
	public static void createDeploymentPlan(Class selectedComposite) {
		Package depPlans = DepPlanUtils.getDepPlanRoot(selectedComposite);

		try {
			final String depPlanName = selectedComposite.getName() + DeployConstants.DepPlanPostfix;
			Package cdp = depPlans.createNestedPackage(depPlanName);
			try {
				InstanceSpecification newRootIS = DepCreation.createDepPlan(cdp, selectedComposite,
						DeployConstants.MAIN_INSTANCE, true);
				DepCreation.initAutoValues(newRootIS);
			} catch (TransformationException e) {
				e.printStackTrace();
			}

		} catch (Exception e) {
			e.printStackTrace();
		}
	}
}
