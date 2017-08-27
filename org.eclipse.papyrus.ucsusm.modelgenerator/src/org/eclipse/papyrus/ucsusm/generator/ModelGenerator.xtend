package org.eclipse.papyrus.ucsusm.generator

import java.util.ArrayList
import java.util.HashMap
import java.util.List
import java.util.Map
import java.util.Random
import org.eclipse.core.resources.IProject
import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.EClass
import org.eclipse.emf.ecore.resource.impl.ResourceSetImpl
import org.eclipse.papyrus.MARTE.MARTE_DesignModel.GCM.FlowDirectionKind
import org.eclipse.papyrus.MARTE.MARTE_DesignModel.GCM.FlowPort
import org.eclipse.papyrus.designer.deployment.profile.Deployment.DeploymentPlan
import org.eclipse.papyrus.designer.transformation.profile.Transformation.M2MTrafoChain
import org.eclipse.papyrus.ucsusm.generator.utils.DeploymentPlanUtils
import org.eclipse.papyrus.ucsusm.generator.utils.InvalideFlowPortException
import org.eclipse.papyrus.ucsusm.generator.utils.ModelingUtils
import org.eclipse.papyrus.uml.tools.utils.ConnectorUtil
import org.eclipse.papyrus.uml.tools.utils.StereotypeUtil
import org.eclipse.uml2.common.util.UML2Util
import org.eclipse.uml2.uml.AggregationKind
import org.eclipse.uml2.uml.ChangeEvent
import org.eclipse.uml2.uml.Class
import org.eclipse.uml2.uml.Connector
import org.eclipse.uml2.uml.Element
import org.eclipse.uml2.uml.Event
import org.eclipse.uml2.uml.FinalState
import org.eclipse.uml2.uml.Interface
import org.eclipse.uml2.uml.Model
import org.eclipse.uml2.uml.NamedElement
import org.eclipse.uml2.uml.OpaqueExpression
import org.eclipse.uml2.uml.Package
import org.eclipse.uml2.uml.Port
import org.eclipse.uml2.uml.Property
import org.eclipse.uml2.uml.Pseudostate
import org.eclipse.uml2.uml.PseudostateKind
import org.eclipse.uml2.uml.Region
import org.eclipse.uml2.uml.Signal
import org.eclipse.uml2.uml.SignalEvent
import org.eclipse.uml2.uml.State
import org.eclipse.uml2.uml.StateMachine
import org.eclipse.uml2.uml.TimeEvent
import org.eclipse.uml2.uml.Transition
import org.eclipse.uml2.uml.Type
import org.eclipse.uml2.uml.UMLFactory
import org.eclipse.uml2.uml.UMLPackage
import org.eclipse.uml2.uml.UMLPackage.Literals
import org.eclipse.uml2.uml.Vertex
import org.eclipse.uml2.uml.util.UMLUtil
import org.eclipse.papyrus.designer.languages.cpp.profile.C_Cpp.Include

class ModelGenerator {
	private List<NamedElement> generatedElements = new ArrayList
	private static int NUMBER_OF_STRUCTURAL_ELEMENTS = 200
	private static int NUMBER_OF_BEHAVIOR_ELEMENTS = 2000
	private Map<EClass, Integer> namingMap = new HashMap
	private Random rand = new Random
	private Map<EClass, List<NamedElement>> map = new HashMap
	private Map<Class, List<PortPair>> eligiblePairOfPorts = new HashMap
	
	private static final String SYSTEM_COMPOSITION = "System"
	private static final String EVENT_PACKAGE = "events"
	private static final String SIGNAL_PACKAGE = "signals"
	private String currentPath

	public new() {
		Configuration.initializeDistribution
	}
	
	public static def setNumberofElements(int structural, int behavioral) {
		NUMBER_OF_STRUCTURAL_ELEMENTS = structural;
		NUMBER_OF_BEHAVIOR_ELEMENTS = behavioral
	}

	public def generateAModel(int id, IProject project, String folder) {
		var fileName = "GeneratedModel" + id
		currentPath = ModelingUtils.getPath(project, folder, fileName + ".uml")
		return generateAModel(fileName, currentPath)
	}

	public def generateModels(int numberOfModels, IProject project, String folder) {
		for (var i = 0; i < numberOfModels; i++) {
			var fileName = "GeneratedModel" + i
			currentPath = ModelingUtils.getPath(project, folder, fileName + ".uml")
			generateAModel(fileName, currentPath)
		}
	}

	public def Model generateAModel(String name, String path) {
		val model = UMLFactory.eINSTANCE.createModel
		model.name = name
		var rset = new ResourceSetImpl
		var res = rset.createResource(URI.createURI(path))
		res.contents.add(model)
		ModelingUtils.applyProfile(model, ModelingUtils.MARTE_URI)
		ModelingUtils.applyProfiles(model)
		generateElements
		try {
			for (var i = 0; i < 2; i++) {
				// First loop: create elements and add them to their containers
				// second loop: refine elements and validate constraints
				for (e : generatedElements) {
					switch (e.eClass) {
						case Literals.CONNECTOR: {
							var conn = e as Connector
							if (i == 0) {
								conn.createEnd
								conn.createEnd
								var container = map.get(Literals.CLASS).randomFromCollection as Class
								container.ownedConnectors.add(conn)
							} else {
								var container = conn.eContainer as Class
								var pairs = findEligiblePairOfPorts(container)
								var pair = pairs.chooseAPairandRemove
								if (pair != null) {
									createConnector(conn, pair, container)
								} else {
									conn.destroy
								}
							}
						}
						case Literals.CLASS: {
							if (i == 0) {
								model.packagedElements.add(e as Class)
							} else {
								// //Implement interfaces
								// var clazz = e as Class
								// var providedPorts = clazz.ownedPorts.filter[it.type instanceof Interface && it.]
							}
						}
						case Literals.PROPERTY: {
							if (i == 0) {
								var attr = e as Property
								var container = map.get(Literals.CLASS).randomFromCollection as Class
								var eligibleTypes = container.findEligibleTypesForAttribute
								var Type type = eligibleTypes.randomFromCollection
								if (type == null) {
									type = ModelingUtils.getPrimitiveTypes(model).randomFromCollection
								}

								(container as Class).ownedAttributes.add(attr)
								attr.aggregation = AggregationKind.COMPOSITE_LITERAL
								attr.lower = rand.nextInt(10) + 1 // 1->10
								attr.type = type
							}
						}
						case Literals.PORT: {
							if (i == 0) {
								var p = e as Port
								var container = map.get(Literals.CLASS).randomFromCollection as Class
								if (container.eContainer == null)
									model.ownedTypes.add(container)
								container.ownedPorts.add(p)
								createARandomPortType(p)
								var multiplicity = rand.nextInt(10) + 1 // 1->10
								p.lower = multiplicity
							}
						}
						case Literals.SIGNAL: {
							if (i == 0) {
								var signalPack = model.getOrCreatePackage(SIGNAL_PACKAGE)
								signalPack.ownedTypes.add(e as Signal)
								var eventPack = model.getOrCreatePackage(EVENT_PACKAGE)
								var signalEvent = createElementFromEClass(Literals.SIGNAL_EVENT, false) as SignalEvent
								signalEvent.signal = e as Signal
								eventPack.packagedElements.add(signalEvent)
							}
						}
						case Literals.INTERFACE: {
							if (i == 0) {
								var intf = e as Interface
								for (var j = 0; j < 3; j++) {
									intf.createOwnedOperation(intf.name + "_op" + j, null, null)
								// we do not generate parameters for operations
								}
								model.ownedTypes.add(intf)
							}
						}
						case Literals.STATE_MACHINE: {
							if (i == 0) {
								var container = map.get(Literals.CLASS).
									filter[(it as Class).classifierBehavior == null].toList.
									randomFromCollection as Class
									if (container == null) {
										container = createElementFromEClass(Literals.CLASS, false) as Class
										model.ownedTypes.add(container)
									}
									container.ownedBehaviors.add(e as StateMachine)
									container.classifierBehavior = e as StateMachine
								}
							}
							case Literals.STATE: {
								if (i == 0) {
									var eligibleRegions = map.get(Literals.REGION).filter(Region).filter [
										!e.allOwnedElements.contains(it)
									].toList
									var region = eligibleRegions.randomFromCollection as Region
									if (region == null) {
										e.destroy
									} else {
										region.subvertices.add(e as State)
									}
								}
							}
							case Literals.REGION: {
								if (i == 0) {
									var statemachinesWithoutRegion = map.get(Literals.STATE_MACHINE).filter(
										StateMachine).filter[it.regions.empty].toList
									if (statemachinesWithoutRegion.empty) {
										// choose a state
										var eligibleStates = map.get(Literals.STATE).filter(State).filter [
											!e.allOwnedElements.contains(it)
										].toList
										var containingState = eligibleStates.randomFromCollection as State
										if (containingState == null) {
											var topRegion = map.get(Literals.STATE_MACHINE).filter(StateMachine).filter [
												!it.regions.empty
											].head.regions.head
											containingState = createElementFromEClass(Literals.STATE, false) as State
											topRegion.subvertices.add(containingState)
											containingState.regions.add(e as Region)
										} else {
											while ((e as Region).allOwnedElements.filter(Vertex).toList.contains(
												containingState)) {
												containingState = map.get(Literals.STATE).randomFromCollection as State
											}
											containingState.regions.add(e as Region)
										}
									} else {
										var sm = statemachinesWithoutRegion.randomFromCollection
										sm.regions.add(e as Region)
									}
								}
							}
							case Literals.FINAL_STATE: {
								if (i == 0) {
									var region = map.get(Literals.REGION).randomFromCollection as Region
									if (region == null) {
										e.destroy
									} else {
										region.subvertices.add(e as FinalState)
									}
								}
							}
							case Literals.PSEUDOSTATE: {
								if (i == 0) {
									(e as Pseudostate).kind = PseudostateKind.VALUES.randomFromCollection
									if ((e as Pseudostate).kind == PseudostateKind.ENTRY_POINT_LITERAL ||
										(e as Pseudostate).kind == PseudostateKind.EXIT_POINT_LITERAL) {
										var composite = map.get(Literals.STATE).filter(State).filter[it.isComposite].
											toList.randomFromCollection as State
										if (composite == null) {
											composite = map.get(Literals.STATE).filter(State).filter [
												!(it instanceof FinalState)
											].toList.randomFromCollection as State
											composite.makeCompositeState
										}
										composite.connectionPoints.add(e as Pseudostate)
									} else if ((e as Pseudostate).kind == PseudostateKind.DEEP_HISTORY_LITERAL ||
										(e as Pseudostate).kind == PseudostateKind.SHALLOW_HISTORY_LITERAL) {
										var region = map.get(Literals.REGION).filter(Region).filter[it.eContainer != null].toList.randomFromCollection as Region
										if (region == null) {
											var composite = map.get(Literals.STATE).filter(State).filter[it.isComposite].
												toList.randomFromCollection as State
											if (composite == null) {
												composite = map.get(Literals.STATE).filter(State).filter [
													!(it instanceof FinalState)
												].toList.randomFromCollection as State
												composite.makeCompositeState
											}
											region = composite.regions.randomFromCollection
										}
										region.subvertices.add(e as Pseudostate)										
									} else {
										var region = map.get(Literals.REGION).randomFromCollection as Region
										if (region == null) {
											e.destroy
										} else {
											region.subvertices.add(e as Pseudostate)
										}
									}
								} else {
									
								}
							}
							case Literals.TRANSITION: {
								if (i == 0) {
									// choose a region and kind
									var region = map.get(Literals.REGION).randomFromCollection as Region
									if (region == null) {
										e.destroy
									} else {
										region.transitions.add(e as Transition)
									}
									(e as Transition).kind == PseudostateKind.VALUES.randomFromCollection
								} else {
									var trans = e as Transition
									var region = e.eContainer as Region
									var allVertexes = region.findStateMachine.allOwnedElements.filter(Vertex).toList
									var Vertex source
									var Vertex target
									var notPass = true
									while (notPass) {
										source = allVertexes.randomFromCollection
										val sourceFinal = source
										var eligibleTargets = new ArrayList<Vertex>
										if (source instanceof Pseudostate) {
											if (source.kind == PseudostateKind.ENTRY_POINT_LITERAL) {
												eligibleTargets.addAll(
													allVertexes.filter[(sourceFinal.eContainer as State).allOwnedElements.contains(it)]
																.filter[!(it instanceof FinalState)]
												)
											} else if (source.kind == PseudostateKind.EXIT_POINT_LITERAL) {
												eligibleTargets.addAll(
													allVertexes.filter[!(sourceFinal.eContainer as State).allOwnedElements.contains(it)])	
											} else {
												eligibleTargets.addAll(allVertexes)
											}
										} else {
											eligibleTargets.addAll(allVertexes)
										}
										
										target = eligibleTargets.randomFromCollection
										notPass = (source == target && source instanceof Pseudostate) ||
										(source instanceof FinalState) || 
										(target instanceof Pseudostate && (target as Pseudostate).kind == PseudostateKind.INITIAL_LITERAL) ||
										(source instanceof Pseudostate && (source as Pseudostate).kind == PseudostateKind.INITIAL_LITERAL) ||
										(source instanceof Pseudostate && target instanceof Pseudostate && (source as Pseudostate).kind == PseudostateKind.ENTRY_POINT_LITERAL 
											&& (target as Pseudostate).kind == PseudostateKind.EXIT_POINT_LITERAL
										)
										if ((source.eContainer as Element).allOwnedElements.contains(target)) {
											if (target instanceof FinalState) {
												notPass = true
											}
										}
										
									}
									trans.source = source
									trans.target = target
									var eventDraw = new ArrayList<Integer>
									eventDraw.add(1);
									eventDraw.add(2);
									eventDraw.add(3);
									eventDraw.add(4);
									if (eventDraw.randomFromCollection != 1) {
										// not a completion event
										if (source instanceof State) {
											var trigger = trans.createTrigger("")
											var allEvents = new ArrayList<Event>
											allEvents.addAll(map.get(Literals.SIGNAL_EVENT).filter(SignalEvent))
											allEvents.addAll(map.get(Literals.TIME_EVENT).filter(TimeEvent))
											allEvents.addAll(map.get(Literals.CHANGE_EVENT).filter(ChangeEvent))
											trigger.event = allEvents.randomFromCollection
										}
									}
								}
							}
							case Literals.CHANGE_EVENT: {
								if (i == 0) {
									var changeEvent = e as ChangeEvent
									var OpaqueExpression opExpression = changeEvent.createChangeExpression("", null,
										UMLPackage.Literals.OPAQUE_EXPRESSION) as OpaqueExpression
									opExpression.bodies.add("true")
									opExpression.languages.add("C++")
									model.getOrCreatePackage(EVENT_PACKAGE).packagedElements.add(changeEvent)
								}
							}
							case Literals.TIME_EVENT: {
								if (i == 0) {
									var timeEvent = e as TimeEvent
									var duration = rand.nextInt(10000) + 1
									var createdEventName = '''TE - {value=«duration», unit=ms}'''
									timeEvent.name = createdEventName
									var w = timeEvent.createWhen("", null)
									var op = w.createExpr("", null,
										UMLPackage.Literals.OPAQUE_EXPRESSION) as OpaqueExpression
									op.bodies.add('''{value=«duration», unit=ms}''')
									model.getOrCreatePackage(EVENT_PACKAGE).packagedElements.add(timeEvent)
								}
							}
							default: {
							}
						}
					}
				}
				refineStateMachine
				generateDefaultImplementation
				model.createSystemComposition
				addConstructs(model)
				saveAModel(model)
			} catch (InvalideFlowPortException e) {
				println(e.message)
				println("Invalid contraints for model " + model.name)
				model.destroy
			} catch (Exception e) {
				e.printStackTrace
				model.destroy
			}
			
		return model
	}
	
	def refineInitialPseudoState(Region r) {
		var initials = r.subvertices.filter(Pseudostate).filter[it.kind == PseudostateKind.INITIAL_LITERAL].toList
		if (initials.empty) {
			var initial = createElementFromEClass(Literals.PSEUDOSTATE, false) as Pseudostate
			initial.kind = PseudostateKind.INITIAL_LITERAL
			r.subvertices.add(initial)
			initials.add(initial)
		}
		for(var i = 0; i < initials.size - 1; i++) {
			initials.get(i).container.subvertices.remove(initials.get(i))
		}
		
		var unique = initials.get(initials.size - 1)
		var transition = createElementFromEClass(Literals.TRANSITION, false) as Transition
		transition.source = unique
		transition.target = r.subvertices.filter(State).filter[!(it instanceof FinalState)].head
		r.transitions.add(transition)
	}
	
	def addConstructs(Model m) {
		StereotypeUtil.apply(m, Include)
		var include = UMLUtil.getStereotypeApplication(m, Include)
	}
	
	def refineStateMachine() {
		//refine regions
		map.get(Literals.REGION).filter(Region).forEach[
			it.createAStateWithinRegion
			it.refineInitialPseudoState
		]
		
		// refine state machine elements: choice + junction + fork + join
		var pseudoStates = map.get(Literals.PSEUDOSTATE).filter(Pseudostate)
		var choiceJunctions = pseudoStates.filter [
			kind == PseudostateKind.CHOICE_LITERAL || kind == PseudostateKind.JUNCTION_LITERAL
		].toList
		choiceJunctions.forEach [
			var noGuardTransition = it.outgoings.filter[it.guard == null].head
			if (it.outgoings.empty || noGuardTransition == null) {
				var createdTransition = it.container.createTransition("")
				createdTransition.source = it
				createdTransition.target = it.container.findStateMachine.allOwnedElements.filter(Vertex).toList.
					randomFromCollection
			}
		]

		var forks = pseudoStates.filter[kind == PseudostateKind.FORK_LITERAL].toList
		forks.forEach [
			var concurrentState = it.container.findOrcreateConcurrentState
			if (it.outgoings.size > concurrentState.regions.size) {
				for (var i = 0; i < it.outgoings.size - concurrentState.regions.size; i++) {
					it.outgoings.randomFromCollection.destroy
				}
			} else {
				for (var i = 0; i < concurrentState.regions.size - it.outgoings.size; i++) {
					var createdTrans = createElementFromEClass(Literals.TRANSITION, false) as Transition
					createdTrans.source = it
					container.transitions.add(createdTrans)
				}
			}

			for (var i = 0; i < it.outgoings.size; i++) {
				it.outgoings.get(i).target = concurrentState.regions.get(i).allOwnedElements.filter(State).filter [
					!(it instanceof FinalState)
				].toList.randomFromCollection
			}

		]

		var joins = pseudoStates.filter[kind == PseudostateKind.JOIN_LITERAL].toList
		joins.forEach [
			var concurrentState = it.container.findOrcreateConcurrentState
			if (it.incomings.size > concurrentState.regions.size) {
				for (var i = 0; i < it.incomings.size - concurrentState.regions.size; i++) {
					it.incomings.randomFromCollection.destroy
				}
			} else {
				for (var i = 0; i < concurrentState.regions.size - it.incomings.size; i++) {
					var createdTrans = createElementFromEClass(Literals.TRANSITION, false) as Transition
					createdTrans.target = it
					container.transitions.add(createdTrans)
				}
			}

			for (var i = 0; i < it.incomings.size; i++) {
				it.incomings.get(i).source = concurrentState.regions.get(i).allOwnedElements.filter(State).filter [
					!(it instanceof FinalState)
				].toList.randomFromCollection
			}
			
			if (it.outgoings.size > 1) {
				for (var i = 0; i < it.outgoings.size - 1; i++) {
					var o = it.outgoings.get(i)
					o.container.transitions.remove(o)
				}
			} else {
				var createdTrans = createElementFromEClass(Literals.TRANSITION, false) as Transition
				createdTrans.source = it
				createdTrans.target = it.container.findStateMachine.allOwnedElements.filter(State).head
				container.transitions.add(createdTrans)
			}

		]
		
		//refine entry point
		for(p:pseudoStates) {
			p.refineConnectionPoint
		}
	}
	
	def refineConnectionPoint(Pseudostate p) {
		val isExitPoint = (p.kind == PseudostateKind.EXIT_POINT_LITERAL)
		val isEntryPoint = (p.kind == PseudostateKind.ENTRY_POINT_LITERAL)
		if (!isExitPoint && !isEntryPoint) {
			return
		}
		var state = p.eContainer as State
		var regions = state.regions
		val Map<Region, List<Transition>> pMap = new HashMap
		regions.forEach[
			pMap.put(it, new ArrayList)
			val r = it
			p.outgoings.forEach[
				if (isExitPoint) {
					if (r.allOwnedElements.contains(it.source)) {
						pMap.get(r).add(it)
					}
				} else {
					if (r.allOwnedElements.contains(it.target)) {
						pMap.get(r).add(it)
					}
				}
			]
		]
		pMap.forEach[r, l|
			if (l.size > 1) {
				for(var i = 0; i < l.size - 1; i++) {
					l.get(i).container.transitions.remove(l.get(i))
				}
			}
		]
		
		//an Exit point has only one outgoing transition 
		if (isExitPoint) {
			var validTrans = p.outgoings.filter[!(p.eContainer as Element).allOwnedElements.contains(it.target)].head
			if (validTrans == null) {
				validTrans = createElementFromEClass(Literals.TRANSITION, false) as Transition
				(p.eContainer as State).container.transitions.add(validTrans)
				validTrans.source = p
				val container = p.eContainer as State
				validTrans.target = container.container
											 .findStateMachine.allOwnedElements	//all elements of state machine
											 .filter[!container.allOwnedElements.contains(it)] //not contained by the containing state of the exit point
											 .filter(Vertex)		
											 .filter[!(it instanceof FinalState)]	//target not a final state
											 .toList
											 .randomFromCollection
			}
			for(o:p.outgoings) {
				if (o != validTrans) {
					o.container.transitions.remove(o)
				}
			}
		}
	}
	
	def createSystemComposition(Model model) {
		// Create a system composition
		val system = model.createOwnedClass(SYSTEM_COMPOSITION, false) as Class
		map.get(Literals.CLASS).filter(Class).forEach [
			system.createOwnedAttribute(it.name.toLowerCase, it).aggregation = AggregationKind.COMPOSITE_LITERAL
		]
		var eligiblePairs = system.findEligiblePairOfPorts
		eligiblePairs.forEach [
			var conn = createElementFromEClass(Literals.CONNECTOR, false) as Connector
			conn.createEnd
			conn.createEnd
			conn.createConnector(it, system)
			system.ownedConnectors.add(conn)
		]

		// generate deployment plan
		DeploymentPlanUtils.createDeploymentPlan(system)

		// apply profiles
		var componentLib = ModelingUtils.importOrgetAModel(model, ModelingUtils.COMPONENT_LIB)
		var deploymentPlanPackage = model.getNestedPackage("deployment").nestedPackages.head
		StereotypeUtil.apply(deploymentPlanPackage, DeploymentPlan)
		var chain = componentLib.getNestedPackage("transformations").getOwnedType("ComponentChain")
		UMLUtil.getStereotypeApplication(deploymentPlanPackage, DeploymentPlan).chain = UMLUtil.
			getStereotypeApplication(chain, M2MTrafoChain)
			
	}
	
	def generateDefaultImplementation() {
		// generate default implementation for provided and in/inout flow port
		for (clazz : map.get(Literals.CLASS).filter(Class)) {
			var providedPorts = clazz.ownedPorts.filter[it.type instanceof Interface && !it.provideds.empty].filter [
				ConnectorUtil.getDelegation(clazz, it) == null
			].toList
			for (p : providedPorts) {
				if (clazz.allImplementedInterfaces.filter[it.name == p.type.name].empty) {
					// generate default implmentation
					clazz.createInterfaceRealization("", p.provideds.head)
					for (op : p.provideds.head.ownedOperations) {
						clazz.createOwnedOperation(op.name, null, null)
					}
				}
			}
			var in_inout_flowPorts = clazz.ownedPorts.filter[it.type instanceof Signal].filter [
				UMLUtil.getStereotypeApplication(it, FlowPort).direction == FlowDirectionKind.IN ||
					UMLUtil.getStereotypeApplication(it, FlowPort).direction == FlowDirectionKind.INOUT
			].filter[ConnectorUtil.getDelegation(clazz, it) == null].toList
			if (!in_inout_flowPorts.empty) {
				var sm = clazz.classifierBehavior
				if (sm != null) {
					if (sm instanceof StateMachine) {
						val allTransitions = sm.allOwnedElements.filter(Transition).toList
						val signalsOfTransitions = allTransitions.filter[!it.triggers.empty].map [
							it.triggers.head
						].map[it.event].filter(SignalEvent).map[it.signal].toList
						in_inout_flowPorts.forEach [
							val signalType = it.type
							if (!signalsOfTransitions.contains(it.type)) {
								var eligibleTransitions = allTransitions.filter[it.source instanceof State].toList
								var modifiedTransition = eligibleTransitions.randomFromCollection
								var trigger = modifiedTransition.triggers.head
								if (trigger == null) {
									trigger = modifiedTransition.createTrigger("")
								}
								trigger.event = model.getOrCreatePackage(EVENT_PACKAGE).ownedElements.filter(
									SignalEvent).filter[it.signal == signalType].head
							}
						]
					}
				} else {
					// delegate to an inner part
					var pairs = clazz.findEligiblePairOfPorts
					for (p : in_inout_flowPorts) {
						val signal = p.type as Signal
						var pair = pairs.filter[it.aPort.type == signal].filter [
							it.aPort == p || it.otherPort == p
						].head
						if (pair == null) {
							throw new InvalideFlowPortException("Invalid constraint")
						}
						pairs.remove(pair)
						var connector = createElementFromEClass(Literals.CONNECTOR, false) as Connector
						clazz.ownedConnectors.add(connector)
						connector.createEnd
						connector.createEnd
						createConnector(connector, pair, clazz)
					}
				}
			}
		}
	}
	
	def makeCompositeState(State s) {
		var r = createElementFromEClass(Literals.REGION, false) as Region
		s.regions.add(r)
		r.createAStateWithinRegion
	}
	
	def createAStateWithinRegion(Region r) {
		if (r.subvertices.filter(State).filter[!(it instanceof FinalState)].empty) {
			var state = createElementFromEClass(Literals.STATE, false) as State
			r.subvertices.add(state)
		}
	}
	
	def findOrcreateConcurrentState(Region container) {
		var compositeStates = container.subvertices.filter(State).filter[it.isComposite].toList
		var concurrentState = compositeStates.filter[it.isOrthogonal].toList.randomFromCollection
		if (concurrentState == null) {
			concurrentState = compositeStates.randomFromCollection
			if (concurrentState == null) {
				concurrentState = container.subvertices.filter(State).filter[!(it instanceof FinalState)].toList.randomFromCollection
				var createdRegion = createElementFromEClass(Literals.REGION, false) as Region
				concurrentState.regions.add(createdRegion)
			}
			var createdRegion = createElementFromEClass(Literals.REGION, false) as Region
			concurrentState.regions.add(createdRegion)
		}
		concurrentState.regions.forEach[
			if (it.allOwnedElements.filter(State).filter[!(it instanceof FinalState)].empty) {
				var createdState = createElementFromEClass(Literals.STATE, false) as State
				it.subvertices.add(createdState)
			}
		]
		return concurrentState
	}
		
	def List<Class> findStackClassHierachy(Class clazz) {
		// we need to find to stack composition hierarchy of this class
		// the purpose is for attribute type selection to avoid circular composition
		val List<Class> ret = new ArrayList
		ret.add(clazz)
		val allTypedProperties = map.get(Literals.PROPERTY).filter(Property).filter[it.type == clazz].toList
		// add all components that contain attributes typed by the clazz
		val containers = allTypedProperties.map[it.eContainer as Class].toList
		// ret.addAll(containers)
		// add all class hierarchy of the containers of the attributes typed by the clazz
		containers.forEach [
			ret.addAll(it.findStackClassHierachy)
		]

		return ret
	}
		
	def List<Class> findEligibleTypesForAttribute(Class clazz) {
		val stack = clazz.findStackClassHierachy
		val allTypes = map.get(Literals.CLASS).filter(Class).toList
		return allTypes.filter[!stack.contains(it)].toList
	}

	def StateMachine findStateMachine(Region r) {
		if (r.containingStateMachine != null) {
			return r.containingStateMachine
		} else {
			return r.state.container.findStateMachine
		}
	}

	def createConnector(Connector conn, PortPair pair, Class container) {
		conn.ends.head.role = pair.aPort
		conn.ends.head.partWithPort = pair.aPart
		conn.ends.last.role = pair.otherPort
		conn.ends.last.role = pair.otherPart
		var productHeadEnd = 1
		var productLastEnd = 1
		if (pair.aPort.eContainer == container) {
			productHeadEnd = pair.aPort.lower
			productLastEnd = pair.otherPart.lower * pair.otherPort.lower
		} else if (pair.otherPort.eContainer == container) {
			productLastEnd = pair.otherPort.lower
			productHeadEnd = pair.aPart.lower * pair.aPort.lower
		} else {
			productHeadEnd = pair.aPart.lower * pair.aPort.lower
			productLastEnd = pair.otherPart.lower * pair.otherPort.lower
		}
		if (productHeadEnd != productLastEnd) {
			// a star pattern 
			conn.ends.head.lower = productHeadEnd
			conn.ends.last.lower = productLastEnd
		}
	}

	def getOrCreatePackage(Package parent, String name) {
		var ret = parent.getNestedPackage(name)
		if (ret == null) {
			ret = parent.createNestedPackage(name)
		}
		return ret
	}

	private def PortPair chooseAPairandRemove(List<PortPair> pairs) {
		if (pairs == null || pairs.empty) {
			return null
		}
		return pairs.randomFromCollection
	}

	private def List<PortPair> findEligiblePairOfPorts(Class container) {
		var ret = eligiblePairOfPorts.get(container)
		if (ret != null) {
			return ret
		}
		ret = new ArrayList
		val List<PartPort> allPorts = new ArrayList
		allPorts.addAll(container.ownedPorts.map[new PartPort(null, it)])
		for (attr : container.ownedAttributes.filter[!(it instanceof Port) && it.type instanceof Class]) {
			(attr.type as Class).ownedPorts.forEach [
				allPorts.add(new PartPort(attr, it))
			]
		}

		// Pairing ports
		for (p1 : allPorts) {
			for (p2 : allPorts) {
				// a port cannot connect to itself and two ports of the same component cannot connect with each other
				if (p1 != p2 && p1.port.eContainer != p2.port.eContainer && p1.port.type == p2.port.type) {
					var isSameTypeofPort = (StereotypeUtil.isApplied(p1.port, FlowPort) ==
						StereotypeUtil.isApplied(p2.port, FlowPort))
					if (isSameTypeofPort) {
						var flowPort1 = UMLUtil.getStereotypeApplication(p1.port, FlowPort)
						var flowPort2 = UMLUtil.getStereotypeApplication(p2.port, FlowPort)
						var isPairable = false
						if (p1.port.eContainer == container) {
							// Check if delegation connector
							if (flowPort1 != null) {
								if (flowPort1.direction == flowPort2.direction ||
									flowPort1.direction == FlowDirectionKind.INOUT ||
									flowPort2.direction == FlowDirectionKind.INOUT) {
									isPairable = true
								}
							} else {
								if (p1.port.conjugated == p2.port.conjugated) {
									isPairable = true
								}
							}
						} else {
							// Assembly connector
							if (flowPort1 != null) {
								if (flowPort1.direction != flowPort2.direction ||
									(flowPort1.direction == FlowDirectionKind.INOUT &&
										flowPort2.direction == FlowDirectionKind.INOUT)) {
									isPairable = true
								}
							} else {
								if (p1.port.conjugated != p2.port.conjugated) {
									isPairable = true
								}
							}
						}
						if (isPairable) {
							val pair = new PortPair(p1.part, p1.port, p2.port, p2.part)
							if (ret.filter[PortPair.compare(it, pair)].empty) {
								ret.add(pair)
							}
						}
					}
				}
			}
		}

		return ret
	}

	private def createARandomPortType(Port p) {
		var random = rand.nextInt(10)
		switch (random) {
			case 0,
			case 1: { // required port
				p.type = map.get(Literals.INTERFACE).randomFromCollection as Interface
				p.isConjugated = true
			}
			case 2,
			case 3: { // provided port
				p.type = map.get(Literals.INTERFACE).randomFromCollection as Interface
			}
			case 4,
			case 5,
			case 6: { // in flow port
				p.type = map.get(Literals.SIGNAL).randomFromCollection as Signal
				StereotypeUtil.apply(p, FlowPort)
				UMLUtil.getStereotypeApplication(p, FlowPort).direction = FlowDirectionKind.IN
			}
			case 7,
			case 8: { // out flow port
				p.type = map.get(Literals.SIGNAL).randomFromCollection as Signal
				StereotypeUtil.apply(p, FlowPort)
				UMLUtil.getStereotypeApplication(p, FlowPort).direction = FlowDirectionKind.OUT
			}
			case 9: { // in out flow port
				p.type = map.get(Literals.SIGNAL).randomFromCollection as Signal
				StereotypeUtil.apply(p, FlowPort)
				UMLUtil.getStereotypeApplication(p, FlowPort).direction = FlowDirectionKind.INOUT
			}
			default: {
			}
		}
	}

	private def <T> randomFromCollection(List<T> l) {
		if (l.empty) {
			return null
		}
		return l.get(rand.nextInt(l.size))
	}

	public def saveAModel(Model m) {
		var res = m.eResource
		for (var allContents = UML2Util.getAllContents(m, true, false); allContents.hasNext();) {
			var eObject = allContents.next();
			if (eObject instanceof Element) {
				res.contents.addAll(eObject.getStereotypeApplications())
			}
		}
		res.save(Configuration.getDefaultSaveOptions());
	}

	public def dispose(Model model) {
		if (model != null) {
			model.destroy
		}
	}

	public def generateElements() {
		for (entry : map.entrySet) {
			if (entry.value != null) {
				entry.value.clear
			}
		}
		generatedElements.clear
		// Create structural elements
		for (var i = 0; i < NUMBER_OF_STRUCTURAL_ELEMENTS; i++) {
			var selectedIndex = rand.nextInt(Configuration.structuralElements.size)
			var selectedEClass = Configuration.structuralElements.get(selectedIndex)
			createElementFromEClass(selectedEClass, true)
		}

		// Ensure every element type has at least an instance created
		for (e : Configuration.structuralElements) {
			if (map.get(e) == null) {
				createElementFromEClass(e, true)
			}
		}

		// Create behavioral elements
		for (var i = 0; i < NUMBER_OF_BEHAVIOR_ELEMENTS; i++) {
			var selectedIndex = rand.nextInt(Configuration.behavioralElements.size)
			var selectedEClass = Configuration.behavioralElements.get(selectedIndex)
			createElementFromEClass(selectedEClass, true)
		}

		// Ensure every element type has at least an instance created
		for (e : Configuration.behavioralElements) {
			if (map.get(e) == null) {
				createElementFromEClass(e, true)
			}
		}
	}

	private def createElementFromEClass(EClass selectedEClass, boolean addToGenerated) {
		var createdElement = UMLFactory.eINSTANCE.create(selectedEClass) as NamedElement
		var nameIndex = namingMap.get(selectedEClass)
		if (nameIndex == null) {
			nameIndex = new Integer(0)
		} else {
			nameIndex++
		}
		namingMap.put(selectedEClass, nameIndex)

		var elementName = selectedEClass.name + nameIndex
		createdElement.name = elementName
		var l = map.get(selectedEClass)
		if (l == null) {
			l = new ArrayList
			map.put(selectedEClass, l)
		}
		l.add(createdElement)
		if (addToGenerated) {
			generatedElements.add(createdElement)
		}
		return createdElement
	}
}
	