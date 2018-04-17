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
import SceneKit.ModelIO

extension MDLMaterial {
    func setTextureProperties(textures: [MDLMaterialSemantic:String]) -> Void {
        for (key,value) in textures {
            var baseTmpUrl = NSTemporaryDirectory()
            baseTmpUrl += "\(value)/\(value).jpg"
            let url = URL(fileURLWithPath: baseTmpUrl)
            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: baseTmpUrl) {
                print("FILE AVAILABLE")
                let property = MDLMaterialProperty(name:value, semantic: key, url: url)
                self.setProperty(property)
            } else {
                print("FILE NOT AVAILABLE")
            }
            
        }
    }
}

class ViewController: UIViewController, ARSCNViewDelegate, MCDelegate, UIGestureRecognizerDelegate {
    
    

    
    
    @IBOutlet weak var modelButton: UIButton!
    
    @IBOutlet var sceneView: ARSCNView!
    
    @IBOutlet weak var deleteButton: UIButton!
    
    
    // Class Variables------------------------------------
    //Check if planes status to see if one is available
    var planes = [UUID: VirtualPlane] ()
    var index = 0
    var selectedPlane: VirtualPlane?
    var modelSelected: SCNNode!
    var valueSentFromModelView: String?
    var returnModelFromList = String()
    var selectedNode: SCNNode?
    var longPressDelay = 0.30
    var modelSelectedString: String?
    var latestTranslatePos: CGPoint?
    var isObjType = String()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        //sceneView.showsStatistics = true
        sceneView.autoenablesDefaultLighting = true
        sceneView.automaticallyUpdatesLighting = true
        
        self.sceneView.debugOptions = []
        
        
        // Initialize View Gesture recognition
        //Tap recognition
        let pressGesture = UITapGestureRecognizer(target: self, action: #selector(addModelToView(gesture:)))
        self.sceneView.addGestureRecognizer(pressGesture)
        //Long Press recognition
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(editOnLongPress(gesture:)))
        longPressGesture.minimumPressDuration = longPressDelay
        self.sceneView.addGestureRecognizer(longPressGesture)
        
        //Drag recognition
        let dragGesture = UIPanGestureRecognizer(target: self, action: #selector(moveModelAround(gesture:)))
        dragGesture.maximumNumberOfTouches = 1
        self.sceneView.addGestureRecognizer(dragGesture)
        
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(scaleSelectedModel(gesture:)))
        let rotationGesture = UIRotationGestureRecognizer(target: self, action: #selector(rotateSelectedModel(gesture:)))
        
        pinchGesture.delegate = self
        rotationGesture.delegate = self
        
        view.addGestureRecognizer(pinchGesture)
        view.addGestureRecognizer(rotationGesture)
        
        //---------------------------------------------------
        
        // Create a new scene
        let scene = SCNScene()
        
        
        // Set the scene to the view
        self.sceneView.scene = scene
        if(returnModelFromList.isEmpty) {
            modelSelectedString = "batman"
            isObjType = "objassets"
            self.initializeObjNode(Modelname: "batman")
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
    
    
    @IBAction func deleteModelAction(_ sender: Any) {
        if(selectedNode != nil) {
            deleteCompleteNode(node: selectedNode!)
            deleteButton.isHidden = true
        }
    }
    
    //Method to initializing the model so it can be added to the scene
    func initializeScnNode(Modelname: String) {
        print("AM : InitializeSCNNode Called")
        // Obtain the scene the coffee mug is contained inside, and extract it.
        let scnScene = SCNScene(named: "\(Modelname).scn", inDirectory: "Models.scnassets/\(Modelname)")!
        let wrapperNode = SCNNode()
        print("AM : SCN File read")
        for child in scnScene.rootNode.childNodes{
            wrapperNode.addChildNode(child)
        }
        self.modelSelected = wrapperNode.clone()
        updateModelLabel(text: Modelname)
    }
    
    //Method to initializing the model so it can be added to the scene
    func initializeObjNode(Modelname: String) {
        // Obtain the scene the coffee mug is contained inside, and extract it.
        print("AM : InitializeObjNode Called")
        print(FileMgr.sharedInstance.root())
        var urltoParse = FileMgr.sharedInstance.root() as String
        urltoParse += "/scannerCache/\(Modelname).obj"
        let url2 = NSURL(string: urltoParse)
        guard let url = Bundle.main.url(forResource: "Models.objassets/\(Modelname)/Model", withExtension: "obj") else {
            fatalError("Failed to find model file.")
        }
        print("AM : OBJ File read")
        let asset = MDLAsset(url: url)
        guard let object = asset.object(at:0) as? MDLMesh else {
            fatalError("Failed to get mesh from asset.")
        }
        print("AM : object file conversion")
        let rootNode = SCNNode()
        let node = SCNNode(mdlObject: object)
        
        // Change node's pivot to fit middle of his bounding box
        alignObjPivot(node)
        
        rootNode.addChildNode(node)
        self.modelSelected = rootNode.clone()
        print("AM : New node added to scene")
        updateModelLabel(text: Modelname)
    }
    
    func initializeObjRunTimeNode(Modelname: String) {
        // Obtain the scene the coffee mug is contained inside, and extract it.
        print("AM : initializeObjRunTimeNode Called")
        print(FileMgr.sharedInstance.root())
        var urltoParse = FileMgr.sharedInstance.root() as String
        urltoParse += "/scannerCache/scannedObjs/\(Modelname).zip"
        
//        print("MALO_Creating_TMP_FOLDER")
//        do{
//            try FileManager.default.createDirectory(at: URL(fileURLWithPath: dest), withIntermediateDirectories: true, attributes: nil)
//        }
//        catch{
//            print("MALO_FAILED_TO_ADD_DIRECTORY_ScannedObjs/modelunziped")
//        }
        
        print("Unzipping...")
        var tmpDirectory = NSTemporaryDirectory() as String
        tmpDirectory += "\(Modelname)"
        
        let unzipSuccess: Bool = SSZipArchive.unzipFile(atPath: urltoParse, toDestination: tmpDirectory)
        print(unzipSuccess)
        
        var urlToObjUnzipped = tmpDirectory
        urlToObjUnzipped += "/\(Modelname).obj"
        
        do{
            let items = try FileManager.default.contentsOfDirectory(atPath: tmpDirectory)
            for item in items {
                print(item)
            }
        }
        catch{
            
        }

        var textureMTL = tmpDirectory
        var basemate = textureMTL + "/\(Modelname)"
        textureMTL += "/\(Modelname).jpg"
        print(textureMTL)
        let scatFunc = MDLScatteringFunction()
        let materialMDL = MDLMaterial(name: basemate, scatteringFunction: scatFunc)

        materialMDL.setTextureProperties(textures: [
            .baseColor:Modelname])
        
//        let material = SCNMaterial()
//        material.diffuse.contents = UIImage(named: textureMTL)
//        sphere.materials = [material]
        
        let url2 = NSURL(string: urlToObjUnzipped)
        print("AM : OBJ File read")
        let asset = MDLAsset(url: url2! as URL)
        guard let object = asset.object(at:0) as? MDLMesh else {
            fatalError("Failed to get mesh from asset.")
        }
        for submesh in object.submeshes! {
            if let submesh = submesh as? MDLSubmesh{
                submesh.material = materialMDL
            }
        }
        print("AM : object file conversion")
        let rootNode = SCNNode()
        let node = SCNNode(mdlObject: object)
        
        
        //Modification Node ICI
        alignObjPivot(node)
        rootNode.addChildNode(node)
        self.modelSelected = rootNode.clone()
        print("AM : New node added to scene")
        updateModelLabel(text: Modelname)
    }
    // Method to align new obj Object
    func alignObjPivot(_ node: SCNNode){
        // Flip the obj around because the scanner export them upside down
        let rotation = SCNAction.rotateBy(x: CGFloat( Double.pi), y: 0.0, z: 0.0, duration: 0.0)
        node.runAction(rotation)
        
        // Get the distance between axis from top left to bottom right
        let bound = SCNVector3(
            x: node.boundingBox.max.x - node.boundingBox.min.x,
            y: node.boundingBox.max.y - node.boundingBox.min.y,
            z: node.boundingBox.max.z - node.boundingBox.min.z)
        
        // Change the node pivot point to fit the middle of the object
        node.pivot = SCNMatrix4MakeTranslation(node.boundingBox.max.x - (bound.x / 2),node.boundingBox.max.y, node.boundingBox.max.z - (bound.z / 2))
    }
    
    // Method delegate to change model after selection from modelViewController
    func passingModelSelection(modelSelection: String, type: String){
        modelSelectedString = modelSelection
        isObjType = type
        if(type.contains("objassets")){
            initializeObjNode(Modelname: modelSelection)
        }
        else if (type.contains("scnassets")){
            initializeScnNode(Modelname: modelSelection)
        } else {
            initializeObjRunTimeNode(Modelname: modelSelection)
        }
        
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
                    deleteButton.isHidden = false
                    
                }
                else {
                    if(selectedNode == node) {
                        unselectSelectedModel()
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
        for child in (node.childNodes) {
            child.removeFromParentNode()
        }
    }
    
    @objc func addModelToView(gesture: UITapGestureRecognizer) {
        
        if gesture.state == .ended
        {
            if(selectedNode != nil){
                unselectSelectedModel()
            }
            else{
                 let touchPoint = gesture.location(in: sceneView)
                 if let plane = virtualPlaneProperlySet(touchPoint: touchPoint) {
                    addModelToPlane(plane: plane, atPoint: touchPoint)
                 }
            }
        }
    }
    func addModelToPlane(plane: VirtualPlane, atPoint point: CGPoint) {
        let hits = sceneView.hitTest(point, types: .existingPlaneUsingExtent)
        if hits.count > 0, let firstHit = hits.first {
            let newModelToScene = modelSelected.clone()
            newModelToScene.position = SCNVector3Make(firstHit.worldTransform.columns.3.x, firstHit.worldTransform.columns.3.y, firstHit.worldTransform.columns.3.z)
            sceneView.scene.rootNode.addChildNode(newModelToScene)
            passingModelSelection(modelSelection: modelSelectedString!, type: isObjType)
        }
    }
    
    func unselectSelectedModel(){
        if(selectedNode != nil){
            highLightNodeChildren(parentNodeToHighLight: selectedNode!, highLight: false)
            selectedNode = nil
            deleteButton.isHidden = true
        }
    }
    
    
    // Used help from https://stackoverflow.com/questions/44729610/dragging-scnnode-in-arkit-using-scenekit to understand how UIPanGestureRecognizer worked and changed it
    // to fit our needs
    @objc func moveModelAround(gesture: UIPanGestureRecognizer){
        /*let position = gesture.location(in: self.sceneView)
        let state = gesture.state
        
        if(state == .failed || state == .cancelled){
            print("Error while dragging object")
            return
        }
        
        else if let _ = selectedNode{
            let deltaX = Float(position.x - latestTranslatePos!.x)/800
            let deltaY = Float(position.y - latestTranslatePos!.y)/800
            selectedNode!.localTranslate(by: SCNVector3Make(deltaX, 0.0, deltaY))
            latestTranslatePos = position
            
        }*/
        // Find the location in the view
        let location = gesture.location(in: sceneView)
        
        if(gesture.state == .changed && selectedNode != nil){
            // Move the node based on the real world translation
            guard let result = sceneView.hitTest(location, types: .existingPlane).first else { return }
            
            let transform = result.worldTransform
            let newPosition = float3(transform.columns.3.x, (selectedNode?.position.y)!, transform.columns.3.z)
            selectedNode?.simdPosition = newPosition
        }
    }
    
    //Handle models scaling in scene
    @objc func scaleSelectedModel(gesture: UIPinchGestureRecognizer){
        if(selectedNode != nil) {
            let pinch = SCNAction.scale(by: gesture.scale, duration: 0.0)
            selectedNode?.runAction(pinch)
            gesture.scale = 1.0
        }
    }
    @objc func rotateSelectedModel(gesture: UIRotationGestureRecognizer) {
        if(selectedNode != nil) {
            let rotation = SCNAction.rotateBy(x: 0.0, y: -gesture.rotation*2.5, z: 0.0, duration: 0.0)
            selectedNode?.runAction(rotation)
            gesture.rotation = 0.0
        }
    }
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}


