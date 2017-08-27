package org.eclipse.papyrus.ucsusm.generator.utils

import org.eclipse.uml2.uml.Model
import org.eclipse.emf.common.util.URI
import org.eclipse.uml2.uml.Profile
import java.util.List
import java.util.ArrayList
import org.eclipse.core.resources.IFile
import org.eclipse.core.runtime.CoreException
import org.eclipse.core.resources.IFolder
import org.eclipse.core.resources.IProject
import org.eclipse.uml2.uml.Type

class ModelingUtils {
	public static String COMPONENT_LIB = "pathmap://DML_C_CORE/componentlib.uml"
	
	public static String MARTE_URI = "pathmap://Papyrus_PROFILES/MARTE.profile.uml"
	public static String ansiUri = "pathmap://PapyrusC_Cpp_LIBRARIES/AnsiCLibrary.uml"
	public static String STANDARD_PROFILE = "pathmap://UML_PROFILES/Standard.profile.uml"
	public static String CPP_PROFILE = "pathmap://PapyrusC_Cpp_PROFILES/C_Cpp.profile.uml"
	public static String FCM_PROFILE = "pathmap://FCM_PROFILES/FCM.profile.uml"
	public static String DEP_PROFILE = "pathmap://DEP_PROFILE/Deployment.profile.uml"
	public static String TRAFO_PROFILE = "pathmap://TRAFO_PROFILE/Transformation.profile.uml"
	//Copied from ReverseCpp2UML
	public static def applyProfile(Model model, String uri) {
		var resource = model.eResource.resourceSet.getResource(URI.createURI(uri), false)
		
		if (resource == null) {
			resource = model.eResource.resourceSet.createResource(URI.createURI(uri))
			resource.load(null)
		}
		
		var profile = resource.contents.filter(typeof(Profile)).head
		if (profile != null && !model.isProfileApplied(profile)) {
			model.applyProfile(profile)
			var ownedProfiles = profile.findAllOwnedProfiles
			ownedProfiles.filter[it != null && !model.isProfileApplied(it)].forEach[model.applyProfile(it)]
		}
		return profile
	}
	
	public static def applyProfiles(Model model) {
		model.applyProfile(STANDARD_PROFILE)
		model.applyProfile(CPP_PROFILE)
		model.applyProfile(FCM_PROFILE)
		model.applyProfile(DEP_PROFILE)
		model.applyProfile(TRAFO_PROFILE)
	}
	
	
	public static def String getPath(IProject project, String subFolder, String filename) {
		var IFile file;
		if (subFolder != null) {
			var IFolder ifolder = project.getFolder(subFolder);
			if (!ifolder.exists()) {
				try {
					ifolder.create(false, true, null);
				} catch (CoreException e) {
					// TODO Auto-generated catch block
					e.printStackTrace();
				}
			}
			file = ifolder.getFile(filename);
		} else {
			file = project.getFile(filename);
		}
		return file.getFullPath().toString();
	}
	
	public static def importOrgetAModel(Model model, String uri) {
		var resource = model.eResource.resourceSet.resources.filter [
			it.URI.path.equals(uri)
		].head
		if (resource == null) {
			resource = model.eResource.resourceSet.createResource(URI.createURI(uri))
			resource.load(null)
		}
		var pack = resource.contents.filter(typeof(Model)).head
		return pack
	}
	
	public def static getPrimitiveTypes(Model m) {
		return importOrgetAModel(m, ansiUri).packagedElements.filter(Type).toList
	}
	
	public static def List<Profile> findAllOwnedProfiles(org.eclipse.uml2.uml.Package pack) {
		val ret = new ArrayList<Profile>
		
		ret.addAll(pack.ownedElements.filter(Profile))
		var nestedPackages = pack.nestedPackages
		nestedPackages.forEach[
			ret.addAll(it.findAllOwnedProfiles)
		]
		
		return ret
	}
}