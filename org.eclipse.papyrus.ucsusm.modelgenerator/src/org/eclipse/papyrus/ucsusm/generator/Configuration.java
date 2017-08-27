package org.eclipse.papyrus.ucsusm.generator;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.eclipse.emf.ecore.EClass;
import org.eclipse.emf.ecore.xmi.XMIResource;
import org.eclipse.emf.ecore.xmi.XMLResource;
import org.eclipse.uml2.uml.UMLPackage.Literals;

public class Configuration {
	public static List<EClass> structuralElements = new ArrayList<EClass>();
	public static List<EClass> behavioralElements = new ArrayList<EClass>();

	public static void initializeDistribution() {
		structuralElements.clear();
		behavioralElements.clear();
		structuralElements.add(Literals.CLASS);
		for (int j = 0; j < 10; j++) {
			structuralElements.add(Literals.PROPERTY);
		}
		for (int j = 0; j < 10; j++) {
			structuralElements.add(Literals.PORT);
		}

		for (int j = 0; j < 5; j++) {
			structuralElements.add(Literals.CONNECTOR);
		}
		for (int j = 0; j < 3; j++) {
			structuralElements.add(Literals.SIGNAL);
		}
		
		for (int j = 0; j < 3; j++) {
			structuralElements.add(Literals.INTERFACE);
		}
		
		behavioralElements.add(Literals.STATE_MACHINE);
		behavioralElements.add(Literals.STATE_MACHINE);
		behavioralElements.add(Literals.STATE_MACHINE);
		behavioralElements.add(Literals.STATE_MACHINE);
		for (int i = 0; i < 4; i++) {
			behavioralElements.add(Literals.REGION);
			behavioralElements.add(Literals.FINAL_STATE);
			for (int j = 0; j < 15; j++) {
				behavioralElements.add(Literals.STATE);
			}
			
			for (int j = 0; j < 5; j++) {
				behavioralElements.add(Literals.PSEUDOSTATE);
			}
			
			for (int j = 0; j < 15; j++) {
				behavioralElements.add(Literals.TRANSITION);
			}
		}
		
		for (int j = 0; j < 2; j++) {
			behavioralElements.add(Literals.CHANGE_EVENT);
			behavioralElements.add(Literals.TIME_EVENT);
		}
		
		//a signal ==> a signal event
		//an operation implementation ==> a call event
	}
	
	public static Map<Object, Object> getDefaultSaveOptions() {
		Map<Object, Object> saveOptions = new HashMap<Object, Object>();

		// default save options.
		saveOptions.put(XMLResource.OPTION_DECLARE_XML, Boolean.TRUE);
		saveOptions.put(XMLResource.OPTION_PROCESS_DANGLING_HREF, XMLResource.OPTION_PROCESS_DANGLING_HREF_DISCARD);
		saveOptions.put(XMLResource.OPTION_SCHEMA_LOCATION, Boolean.TRUE);
		saveOptions.put(XMIResource.OPTION_USE_XMI_TYPE, Boolean.TRUE);
		saveOptions.put(XMLResource.OPTION_SAVE_TYPE_INFORMATION, Boolean.TRUE);
		saveOptions.put(XMLResource.OPTION_SKIP_ESCAPE_URI, Boolean.FALSE);
		saveOptions.put(XMLResource.OPTION_ENCODING, "UTF-8");
		saveOptions.put(XMLResource.OPTION_USE_FILE_BUFFER, true);
		saveOptions.put(XMLResource.OPTION_FLUSH_THRESHOLD, 4 * 1024 * 1024); // 4 MB Buffer

		// see bug 397987: [Core][Save] The referenced plugin models are saved using relative path
		saveOptions.put(XMLResource.OPTION_URI_HANDLER, new org.eclipse.emf.ecore.xmi.impl.URIHandlerImpl.PlatformSchemeAware());

		return saveOptions;
	}
}
