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

  let scene:         SCNScene
  let sceneRenderer: SCNSceneRenderer
  var worlds:        [World] = []

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
  static let None: UInt32 = 0      //  0
  static let Edge: UInt32 = 0b1    //  1
  static let Bone: UInt32 = 0b10   //  2
  static let Cell: UInt32 = 0b100  //  4
}

class World: SKScene {
  var lives: [String: Life] = [:]
  class Sun {
    var node:SKShapeNode? = nil
    var tick:CGFloat = 0
    var position: CGPoint = CGPoint.zero
    var world:World
    init(world:World) {
      self.world = world
    }
    let _WINTER = true
    func update(){
      if _WINTER {
        tick += 1
        power = max(sin(2 * CGFloat.pi * tick / 100) / 2 * 0.30 + 0.7, 0)

        let x = 20 * (20 * power - 3)
        self.node?.removeFromParent()
        self.node = SKShapeNode(circleOfRadius: x)
        node?.strokeColor = SCNColor.yellow
        world.addChild(node!)
      } 
    }
    var power:CGFloat = 1
  }

  var sun: Sun!
  var hudNode: SCNNode {
    let plane    = SCNPlane(width: 5, height: 5)
    let material = SCNMaterial()
    material.lightingModel = SCNMaterial.LightingModel.constant
    material.isDoubleSided = true
    material.diffuse.contents = self
    plane.materials = [material]

    let hudNode = SCNNode(geometry: plane)
    hudNode.name = "HUD"
    hudNode.rotation = SCNVector4(x: 1, y: 0, z: 0, w: 3.14159265)
    hudNode.position = SCNVector3(x: 0, y: 0.5, z: -5)
    return hudNode
  }

  func start() {

    let edge = SKNode()
    edge.physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
    edge.physicsBody!.usesPreciseCollisionDetection = true
    edge.physicsBody!.categoryBitMask = PhysicsCategory.Edge
    addChild(edge)

    // DEBUG
    physicsWorld.gravity = CGVector.zero

    self.sun = Sun(world: self)

    let cell = GreenCell.init(circleOfRadius: cellRadius)
    let life = Life(world: self, cell: cell, gene: Gene(code: Gene.sampleCode))

    cell.position = CGPoint.zero
    cell.energy = 1

    appendLife(life: life, cell: cell)

    isPaused = false
  }

  func appendLife(life: Life, cell: Cell) {
    cell.setup(with: self, life: life, coreStatus: CoreStatus(with: life.gene.code)) {}

    lives[life.name] = life
    addChild(cell as! BaseCell)
  }

  override func update(_ currentTime: TimeInterval) {
    if last == nil {
      last = currentTime
    }

    guard last! + interval <= currentTime else {
      return
    }

    last = currentTime

    lives.forEach({ $0.value.update(currentTime) })
    sun.update()
  }
}

var last:     TimeInterval?
let interval: TimeInterval = 0.1
