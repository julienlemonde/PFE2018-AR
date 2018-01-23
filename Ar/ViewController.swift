//
//  ViewController.swift
//  Ar
//
//  Created by Julien Lemonde on 18-01-17.
//  Copyright © 2018 Julien Lemonde. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import AudioToolbox

class ViewController: UIViewController, ARSCNViewDelegate, MCDelegate {

    
    
    @IBOutlet weak var modelButton: UIButton!
    
    @IBOutlet var sceneView: ARSCNView!
    
    
    
    // Class Variables------------------------------------
    //Check if planes status to see if one is available
    var planes = [UUID: VirtualPlane] ()
    var index = 0
    var selectedPlane: VirtualPlane?
    var nodeSelected: SCNNode!
    var valueSentFromModelView: String?
    var returnModelFromList = String()
    var selectedNode: SCNNode?
    var longPressDelay = 0.5
    var modelSelectedString: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        //sceneView.showsStatistics = true
        sceneView.autoenablesDefaultLighting = true
        sceneView.automaticallyUpdatesLighting = true
        
        self.sceneView.debugOptions = [.showConstraints,.showLightExtents, .showSkeletons,ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
        
        let pressGesture = UITapGestureRecognizer(target: self, action: #selector(addModelToView(gesture:)))
        self.sceneView.addGestureRecognizer(pressGesture)
        
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(editOnLongPress(gesture:)))
        longPressGesture.minimumPressDuration = longPressDelay
        self.sceneView.addGestureRecognizer(longPressGesture)
        
        
        // Create a new scene
        let scene = SCNScene()
        
        
        // Set the scene to the view
        self.sceneView.scene = scene
        if(returnModelFromList.isEmpty) {
            modelSelectedString = "duck"
            self.initializeMugNode(Modelname: "duck")
        }
        
    }
    

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    //Update the label to show which model is selected
    func updateModelLabel(text: String){
        let first = String(text.prefix(1)).capitalized
        let otherLetters = String(text.dropFirst())
        modelButton.setTitle(first + otherLetters, for: [])
    }
    

    // MARK: - ARSCNViewDelegate
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
    }
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if let arPlaneAnchor = anchor as? ARPlaneAnchor {
            let plane = VirtualPlane(anchor: arPlaneAnchor)
            self.planes[arPlaneAnchor.identifier] = plane
            node.addChildNode(plane)
        }
    }
    
    //Method called when a node has been updated with data from the given anchor
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        if let arPlaneAnchor = anchor as? ARPlaneAnchor, let plane = planes[arPlaneAnchor.identifier]{
            plane.updateWithNewAnchor(arPlaneAnchor)
        }
    }
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        if let arPlaneAnchor = anchor as? ARPlaneAnchor, let index = planes.index(forKey: arPlaneAnchor.identifier) {
            planes.remove(at: index)
        }
    }

    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
    func virtualPlaneProperlySet(touchPoint: CGPoint) -> VirtualPlane? {
        let hits = sceneView.hitTest(touchPoint, types: .existingPlaneUsingExtent)
        if hits.count > 0, let firstHit = hits.first, let identifier = firstHit.anchor?.identifier, let plane = planes[identifier] {
            self.selectedPlane = plane
            return plane
        }
        return nil
    }
    

    func cleanupARSession() {
        sceneView.scene.rootNode.enumerateChildNodes { (node, stop) -> Void in
            node.removeFromParentNode()
        }
    }
    
    //Method to initializing the model so it can be added to the scene
    func initializeMugNode(Modelname: String) {
        // Obtain the scene the coffee mug is contained inside, and extract it.
        let mugScene = SCNScene(named: "\(Modelname).scn", inDirectory: "Models.scnassets/\(Modelname)")!
        let wrapperNode = SCNNode()
        
        for child in mugScene.rootNode.childNodes{
            wrapperNode.addChildNode(child)
        }
        self.nodeSelected = wrapperNode.clone()
        updateModelLabel(text: Modelname)
    }
    
    // Method delegate to change model after selection from modelViewController
    func passingModelSelection(modelSelection: String){
        modelSelectedString = modelSelection
        initializeMugNode(Modelname: modelSelection)
    }
    
    // Method to prepare opening the model List view and recover the response
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? modelViewController {
            destination.delegate = self
        }
    }
    @objc func editOnLongPress(gesture: UILongPressGestureRecognizer) {
        if(gesture.state == .began){
            DispatchQueue.main.asyncAfter(deadline: .now() + longPressDelay + 0.1) {
                AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
            }
        }
        
        if gesture.state == .ended {
            let touchLocation = gesture.location(in: self.sceneView)
            let hitResults = sceneView.hitTest(touchLocation, options: [:])
            if !hitResults.isEmpty {
                guard let hitNodeResult = hitResults.first else { return }
                let node = hitNodeResult.node.parent
                if(selectedNode == nil){
                    selectedNode = node
                    highLightNodeChildren(parentNodeToHighLight: node!, highLight: true)
                    
                }
                else {
                    if(selectedNode == node) {
                        highLightNodeChildren(parentNodeToHighLight: node!, highLight: false)
                        selectedNode = nil
                    }
                    else {
                        highLightNodeChildren(parentNodeToHighLight: selectedNode!, highLight: false)
                        highLightNodeChildren(parentNodeToHighLight: node!, highLight: true)
                        selectedNode = node
                    }
                }
            }
        }
    }
    //Method to highLight all children from a parent node Ex: the chair foot and shadow, etc..
    func highLightNodeChildren(parentNodeToHighLight: SCNNode, highLight: Bool){
            for child in parentNodeToHighLight.childNodes{
                if( child.geometry != nil){
                    let nodeMaterial = (child.geometry?.firstMaterial!)
                    if highLight {
                        //Change the outter color for green
                        SCNTransaction.begin()
                        nodeMaterial?.emission.contents = UIColor.green
                        SCNTransaction.commit()
                    }
                    else {
                        // Remove the highLight
                        SCNTransaction.begin()
                        nodeMaterial?.emission.contents = UIColor.black
                        
                        SCNTransaction.commit()
                    }
                }
        }
    }
    
    func deleteCompleteNode(node: SCNNode){
        let parent = node.parent != nil ? node.parent : node
        for child in (parent?.childNodes)! {
            child.removeFromParentNode()
        }
    }
    
    @objc func addModelToView(gesture: UITapGestureRecognizer) {
        
        if gesture.state == .ended
        {
             let touchPoint = gesture.location(in: sceneView)
             if let plane = virtualPlaneProperlySet(touchPoint: touchPoint) {
                addModelToPlane(plane: plane, atPoint: touchPoint)
             }
        }
    }
    func addModelToPlane(plane: VirtualPlane, atPoint point: CGPoint) {
        let hits = sceneView.hitTest(point, types: .existingPlaneUsingExtent)
        if hits.count > 0, let firstHit = hits.first {
            let newModelToScene = nodeSelected.clone()
            newModelToScene.position = SCNVector3Make(firstHit.worldTransform.columns.3.x, firstHit.worldTransform.columns.3.y, firstHit.worldTransform.columns.3.z)
            sceneView.scene.rootNode.addChildNode(newModelToScene)
            initializeMugNode(Modelname: modelSelectedString!)
        }
    }
}
