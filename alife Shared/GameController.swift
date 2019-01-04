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

    let life = Life(world: self)
    addChild(life.cell)
    isPaused = false
    lives.append(life)

  }

  override func update(_ currentTime: TimeInterval) {
    lives.forEach({$0.update(currentTime)})
  }
}

class Life{
  let w:CGFloat = 10
  let cell: SKShapeNode
  let world: World
  init(world: World) {
    self.world = world
    cell = SKShapeNode.init(circleOfRadius: w)
    cell.physicsBody = SKPhysicsBody.init(circleOfRadius: w)
    cell.physicsBody!.categoryBitMask = PhysicsCategory.Cell
    cell.physicsBody!.collisionBitMask = PhysicsCategory.Edge | PhysicsCategory.Cell
  }
  let s:CGFloat = 2
  var up = true
  func update(_ currentTime:TimeInterval){
    if(up) {
      up = false
      appendBone()
    }
  }
  func appendBone() {
    let size = CGSize(width: s, height: s * 30)
    let position = CGPoint(x: cell.position.x - s/2, y: cell.position.y + w/2)
    let bone = SKShapeNode.init(rect: CGRect(origin: position, size: size))
    bone.physicsBody = SKPhysicsBody.init(rectangleOf: size, center: position)
    bone.physicsBody!.categoryBitMask = PhysicsCategory.Bone
    bone.physicsBody!.collisionBitMask = PhysicsCategory.Edge | PhysicsCategory.Bone
    bone.fillColor = NSColor.gray
    bone.zRotation = CGFloat.pi / 6 * 11
    world.addChild(bone)

    let joint = SKPhysicsJointPin.joint(withBodyA: cell.physicsBody!, bodyB: bone.physicsBody!,
                                        anchor: CGPoint(x: cell.frame.midX, y: cell.frame.midY))
    //回転の抵抗を設定する。
    joint.frictionTorque = 0.5
    //最小角度を30度に設定する。
    joint.lowerAngleLimit = CGFloat.pi / 6
    //最大角度を90度に設定する。
    joint.upperAngleLimit = CGFloat.pi * 11 / 6
    //回転角度の制限を有効にする。
    joint.shouldEnableLimits = true
    world.physicsWorld.add(joint)
  }
}
