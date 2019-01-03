//
//  GameController.swift
//  alife Shared
//
//  Created by hayato.iida on 2019/01/03.
//  Copyright © 2019年 hayato.iida. All rights reserved.
//

import SceneKit
import SpriteKit

#if os(watchOS)
import WatchKit
#endif

#if os(macOS)
typealias SCNColor = NSColor
#else
typealias SCNColor = UIColor
#endif

class GameController: NSObject, SCNSceneRendererDelegate {

  let scene: SCNScene
  let sceneRenderer: SCNSceneRenderer
  var worlds:[World] = []

  init(sceneRenderer renderer: SCNSceneRenderer) {
    sceneRenderer = renderer
    scene = SCNScene(named: "Art.scnassets/main.scn")!

    super.init()

    sceneRenderer.delegate = self
    let world = World()
    worlds.append(world)
    scene.rootNode.addChildNode(world.hudNode)
    world.start()
    sceneRenderer.scene = scene
  }

  func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
    // Called before each frame is rendered
  }

}

class World {
  let skScene: SKScene
  let hudNode: SCNNode

  struct PhysicsCategory {
    static let None:        UInt32 = 0      //  0
    static let Edge:        UInt32 = 0b1    //  1
    static let Paddle:      UInt32 = 0b10   //  2
    static let Ball:        UInt32 = 0b100  //  4
  }

  init() {
    skScene = SKScene(fileNamed: "World.sks")!
    //create a plane to put the skScene on
    let plane = SCNPlane(width:5,height:5)
    let material = SCNMaterial()
    material.lightingModel = SCNMaterial.LightingModel.constant
    material.isDoubleSided = true
    material.diffuse.contents = skScene
    plane.materials = [material]

    //Add plane to a node, and node to the SCNScene
    hudNode = SCNNode(geometry: plane)
    hudNode.name = "HUD"
    hudNode.rotation = SCNVector4(x: 1, y: 0, z: 0, w: 3.14159265)
    hudNode.position = SCNVector3(x:0, y: 0, z: 0)
  }


  func start(){
    let w:CGFloat = 10

    //    let firstNode = SKShapeNode.init(rectOf: CGSize.init(width: w, height: w), cornerRadius: w *
    let ball = SKShapeNode.init(circleOfRadius: w)
    ball.physicsBody = SKPhysicsBody.init(circleOfRadius: w)
    ball.physicsBody?.applyForce(CGVector.init(dx: 10, dy: 0))
    self.skScene.addChild(ball)
    self.skScene.isPaused = false

  }
}
