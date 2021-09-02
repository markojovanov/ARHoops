//
//  ViewController.swift
//  ARHoops
//
//  Created by Marko Jovanov on 1.9.21.
//

import UIKit
import SceneKit
import ARKit
import Each

class ViewController: UIViewController, ARSCNViewDelegate {
    
    @IBOutlet var sceneView: ARSCNView!
    let timer = Each(0.05).seconds
    var basketAdded: Bool = false
    var power: Float = 1.0
    override func viewDidLoad() {
        super.viewDidLoad()
        sceneView.delegate = self
        sceneView.autoenablesDefaultLighting = true
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        sceneView.addGestureRecognizer(tapGestureRecognizer)
        tapGestureRecognizer.cancelsTouchesInView = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if basketAdded == true {
            timer.perform { () -> NextStep in
                self.power += 1.0
                return .continue
            }
        }
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if basketAdded == true {
            timer.stop()
            shootBall()
        }
        power = 1
    }
    func shootBall() {
        guard let pointOfView = sceneView.pointOfView else { return }
        removeBall()
        let transfor = pointOfView.transform
        let location = SCNVector3(
            transfor.m41,
            transfor.m42,
            transfor.m43
        )
        let orientation = SCNVector3(
            -transfor.m31,
            -transfor.m32,
            -transfor.m33
        )
        let currentPositon = location + orientation
        let ball = SCNNode(geometry: SCNSphere(radius: 0.25))
        ball.geometry?.firstMaterial?.diffuse.contents = UIImage(named: "ball")
        ball.position = currentPositon
        let body = SCNPhysicsBody(type: .dynamic,
                                  shape: SCNPhysicsShape(node: ball))
        ball.physicsBody = body
        ball.name = "basketball1"
        body.restitution = 0.2
        ball.physicsBody?.applyForce(SCNVector3(
                                        orientation.x * power,
                                        orientation.y * power,
                                        orientation.z * power
                                    ),
                                    asImpulse: true)
        sceneView.scene.rootNode.addChildNode(ball)
    }
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard anchor is ARPlaneAnchor else { return }
    }
    @objc func handleTap(sender: UITapGestureRecognizer) {
        guard let sceneViewTap = sender.view as? ARSCNView else { return }
        let touchLocation = sender.location(in: sceneViewTap)
        let hitTestResult = sceneViewTap.hitTest(touchLocation,
                                                 types: .existingPlaneUsingExtent)
        if !hitTestResult.isEmpty {
            addBasketballCourt(hitTestResult: hitTestResult.first!)
        }
    }
    func addBasketballCourt(hitTestResult: ARHitTestResult) {
        if basketAdded == false {
            if let basketballScene = SCNScene(named: "art.scnassets/Basketball.scn") {
                if let basketNode = basketballScene.rootNode.childNode(withName: "basketball",
                                                                       recursively: false) {
                    let positionOfPlane = hitTestResult.worldTransform.columns.3
                    basketNode.position = SCNVector3(
                        positionOfPlane.x,
                        positionOfPlane.y,
                        positionOfPlane.z
                    )
                    basketNode.physicsBody = SCNPhysicsBody(type: .static,
                                                            shape: SCNPhysicsShape(node: basketNode,
                                                                                   options: [SCNPhysicsShape.Option.keepAsCompound: true,
                                                                                SCNPhysicsShape.Option.type :SCNPhysicsShape.ShapeType.concavePolyhedron]))
                    sceneView.scene.rootNode.addChildNode(basketNode)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        self.basketAdded = true
                    }
                }
            }
        }
    }
    func removeBall() {
        sceneView.scene.rootNode.enumerateChildNodes { node, _ in
            if node.name == "basketball1" {
                node.removeFromParentNode()
            }
        }
    }
    deinit {
        timer.stop()
    }
}

func +(left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    return SCNVector3Make(left.x + right.x, left.y + right.y, left.z + right.z)
}
