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

    let life = Life(world: self)
    addChild(life.cell)
    isPaused = false
    lives.append(life)

  }

  override func update(_ currentTime: TimeInterval) {
    lives.forEach({$0.update(currentTime)})
  }
}

let cellRadius:CGFloat = 1
class Life{
  let cell: Cell
  let world: World
  init(world: World) {
    self.world = world
    cell = Cell.init(circleOfRadius: cellRadius)
    cell.setup(with: world)
  }
  var up = true
  func update(_ currentTime:TimeInterval){
    cell.update(currentTime)
  }
}

class Cell:SKShapeNode{
  var joints:[SKPhysicsJoint] = []
  var energy = 0
  var childCells:[Cell] = []
  let growthEnergy = 10
  var world: World!
  var growth: () -> () = {() in  }

  func setup(with world:World){
    self.world = world
    self.growth = { () in
      self.appendCell(rotate: Int.random(in: 0...3))
      self.growth = {() in }
    }

    self.physicsBody = SKPhysicsBody.init(circleOfRadius: cellRadius)
    physicsBody!.categoryBitMask = PhysicsCategory.Cell
    physicsBody!.collisionBitMask = PhysicsCategory.Edge | PhysicsCategory.Cell

  }
  func update(_ currentTime:TimeInterval){
    energy += 1
    if energy > growthEnergy {
      growth()
      energy -= growthEnergy
    }
    if energy > childCells.count {
      childCells.forEach{$0.energy += 1}
      energy -= childCells.count
    }
    childCells.forEach{$0.update(currentTime)}
  }

  func appendCell(rotate: Int) {
    let length = cellRadius * 3
    let spawnPoint = {() -> CGPoint in
      switch rotate {
      case 0:
        return CGPoint(x: self.position.x, y: self.position.y + length )
      case 1:
        return CGPoint(x: self.position.x - length, y: self.position.y)
      case 2:
        return CGPoint(x: self.position.x, y: self.position.y - length )
      case 3:
        return CGPoint(x: self.position.x + length, y: self.position.y)
      default:
        return CGPoint(x: self.position.x, y: self.position.y)
      }
    }()

    let childCell = Cell.init(circleOfRadius: cellRadius)
    childCell.position = spawnPoint

    childCell.setup(with: world)
    childCell.fillColor = NSColor.gray
    childCells.append(childCell)
    world.addChild(childCell)

    let joint = SKPhysicsJointLimit.joint(withBodyA: physicsBody!, bodyB: childCell.physicsBody!,
                                        anchorA: position,anchorB: childCell.position)
    self.joints.append(joint)
    world.physicsWorld.add(joint)
  }

}
