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

class ViewController: UIViewController, ARSCNViewDelegate {

    
    
    @IBOutlet weak var modelButton: UIButton!
    
    @IBOutlet var sceneView: ARSCNView!
    
    
    
    // Class Variables------------------------------------
    //Check if planes status to see if one is available
    var planes = [UUID: VirtualPlane] ()
    var index = 0
    var modelType: [String] = ["duck","candle","lamp","vase"]
    var selectedPlane: VirtualPlane?
    var mugNode: SCNNode!
    var returnModelFromList = String()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        //sceneView.showsStatistics = true
        sceneView.autoenablesDefaultLighting = true
        sceneView.automaticallyUpdatesLighting = true
        
        self.sceneView.debugOptions = [.showConstraints,.showLightExtents, .showSkeletons,ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
        
        // Create a new scene
        let scene = SCNScene()
        
        
        // Set the scene to the view
        self.sceneView.scene = scene
        if(returnModelFromList.isEmpty) {
            self.initializeMugNode(Modelname: "duck")
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if(!returnModelFromList.isEmpty){
            self.initializeMugNode(Modelname: returnModelFromList)
            sceneView.session.run(sceneView.session.configuration!)
        }
        super.viewWillAppear(animated)
        
        
        // Run the view's session
        if(returnModelFromList.isEmpty) {
            // Create a session configuration
            let configuration = ARWorldTrackingConfiguration()
            configuration.planeDetection = .horizontal
            sceneView.session.run(configuration)
        }
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
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
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
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else {
            print("Unable to identify touches on any plane. Ignoring interaction...")
            return
        }
        
        let touchPoint = touch.location(in: sceneView)
        if let plane = virtualPlaneProperlySet(touchPoint: touchPoint) {
            addCoffeeToPlane(plane: plane, atPoint: touchPoint)
        }
    }
    func virtualPlaneProperlySet(touchPoint: CGPoint) -> VirtualPlane? {
        let hits = sceneView.hitTest(touchPoint, types: .existingPlaneUsingExtent)
        if hits.count > 0, let firstHit = hits.first, let identifier = firstHit.anchor?.identifier, let plane = planes[identifier] {
            self.selectedPlane = plane
            return plane
        }
        return nil
    }
    func addCoffeeToPlane(plane: VirtualPlane, atPoint point: CGPoint) {
        let hits = sceneView.hitTest(point, types: .existingPlaneUsingExtent)
        if hits.count > 0, let firstHit = hits.first {
            if let anotherMugYesPlease = mugNode?.clone() {
                anotherMugYesPlease.position = SCNVector3Make(firstHit.worldTransform.columns.3.x, firstHit.worldTransform.columns.3.y, firstHit.worldTransform.columns.3.z)
                sceneView.scene.rootNode.addChildNode(anotherMugYesPlease)
            }
        }
    }

    func cleanupARSession() {
        sceneView.scene.rootNode.enumerateChildNodes { (node, stop) -> Void in
            node.removeFromParentNode()
        }
    }
    func initializeMugNode(Modelname: String) {
        // Obtain the scene the coffee mug is contained inside, and extract it.
        let mugScene = SCNScene(named: "\(Modelname).scn", inDirectory: "Models.scnassets/\(Modelname)")!
        let wrapperNode = SCNNode()
        
        for child in mugScene.rootNode.childNodes{
            wrapperNode.addChildNode(child)
        }
        self.mugNode = wrapperNode.clone()
        updateModelLabel(text: Modelname)
    }
    
    
    
}
