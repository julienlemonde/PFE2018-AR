//
//  VirtualPlane.swift
//  Ar
//
//  Created by Julien Lemonde on 18-01-17.
//  Copyright © 2018 Julien Lemonde. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class VirtualPlane: SCNNode {
    var anchor: ARPlaneAnchor!
    var planeGeometry: SCNPlane!
    
    init(anchor: ARPlaneAnchor){
        super.init()
        
        // Init default variables
        self.anchor = anchor
        self.planeGeometry = SCNPlane(width: CGFloat(anchor.extent.x), height: CGFloat(anchor.extent.z))
        self.planeGeometry.cornerRadius = 0.12
        let material = initializePlaneMaterial()
        self.planeGeometry.materials = [material]
        
        // Create sceneKit plane node
        let planeNode = SCNNode(geometry: self.planeGeometry)
        planeNode.position = SCNVector3(anchor.center.x, 0, anchor.center.z)
        planeNode.transform = SCNMatrix4MakeRotation(-Float.pi / 2.0, 1.0, 0.0, 0.0)
        planeNode.physicsBody = SCNPhysicsBody(type: .kinematic, shape: SCNPhysicsShape(geometry: self.planeGeometry, options: nil))
        
        updatePlaneMaterialDimensions()
        
        self.addChildNode(planeNode)
    }
    
    private func initializePlaneMaterial() -> SCNMaterial {
        let material = SCNMaterial()
        let meshplane = UIImage(named: "../art.scnassets/wireframe.png")
        material.diffuse.contents = meshplane
        material.diffuse.wrapS = SCNWrapMode.repeat
        material.diffuse.wrapT = SCNWrapMode.repeat
        material.diffuse.contentsTransform = SCNMatrix4MakeScale(Float(planeGeometry.width / 0.15).rounded(),
                                                                 Float(planeGeometry.height / 0.15).rounded(),
                                                                 0)
        return material
    }
    
    func updatePlaneMaterialDimensions(){
        let material = self.planeGeometry.materials.first!
        
        let width = Float(self.planeGeometry.width / 0.15).rounded()
        let height = Float(self.planeGeometry.height / 0.15).rounded()
        material.transparency = 0.65
        material.diffuse.contentsTransform = SCNMatrix4MakeScale(width, height, 1.0)
    }
    func updateWithNewAnchor(_ anchor: ARPlaneAnchor) {
        // first, we update the extent of the plane, because it might have changed
        self.planeGeometry.width = CGFloat(anchor.extent.x)
        self.planeGeometry.height = CGFloat(anchor.extent.z)
        
        // now we should update the position (remember the transform applied)
        self.position = SCNVector3(anchor.center.x, 0, anchor.center.z)
        
        // update the material representation for this plane
        updatePlaneMaterialDimensions()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
