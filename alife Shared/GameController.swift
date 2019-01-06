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
    let world = SKScene(fileNamed: "World")! as! World
    worlds.append(world)
    scene.rootNode.addChildNode(world.hudNode)
    world.start()
    sceneRenderer.scene = scene
  }

  func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
    // Called before each frame is rendered
  }

}

struct PhysicsCategory {
  static let None:        UInt32 = 0      //  0
  static let Edge:        UInt32 = 0b1    //  1
  static let Bone:        UInt32 = 0b10   //  2
  static let Cell:        UInt32 = 0b100  //  4
}

class World:SKScene {
  var lives:[Life] = []
  var hudNode: SCNNode {
    let plane = SCNPlane(width:5,height:5)
    let material = SCNMaterial()
    material.lightingModel = SCNMaterial.LightingModel.constant
    material.isDoubleSided = true
    material.diffuse.contents = self
    plane.materials = [material]

    let hudNode = SCNNode(geometry: plane)
    hudNode.name = "HUD"
    hudNode.rotation = SCNVector4(x: 1, y: 0, z: 0, w: 3.14159265)
    hudNode.position = SCNVector3(x:0, y: 0.5, z: -5)
    return hudNode
  }

  func start(){

    let edge = SKNode()
    edge.physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
    edge.physicsBody!.usesPreciseCollisionDetection = true
    edge.physicsBody!.categoryBitMask = PhysicsCategory.Edge
    addChild(edge)

    // DEBUG
    physicsWorld.gravity = CGVector.zero

    let cell = GreenCell.init(circleOfRadius: cellRadius)
    cell.setup(with: self, gene:Gene())
    cell.position = CGPoint.zero

    appendLife(cell:cell)
    isPaused = false
  }

  func appendLife(cell:BaseCell) {
    let life = Life(world: self,cell: cell)
    addChild(life.cell)
    lives.append(life)
  }

  override func update(_ currentTime: TimeInterval) {
    lives.forEach({$0.update(currentTime)})
  }
}

let cellRadius:CGFloat = 10

class Life{
  let cell: BaseCell
  let world: World
  init(world: World,cell:BaseCell) {
    self.world = world
    self.cell = cell
  }
  func update(_ currentTime:TimeInterval){
    cell.update(currentTime)
  }
}
