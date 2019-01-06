//
//  Cell.swift
//  alife iOS
//
//  Created by hayato.iida on 2019/01/06.
//  Copyright © 2019年 hayato.iida. All rights reserved.
//

import SpriteKit
protocol Cell: class {
  var childCells:[Cell] {get set}
  var joints:[SKPhysicsJoint] {get set}
  var energy:Int {get set}
  static var growthEnergy:Int {get}
  var world:World! {get set}
  var growth: () -> () {get set}
  func setup(with world:World)
  func update(_ currentTime:TimeInterval)
  func work()
  var physicsBody:SKPhysicsBody?{get set}
  var position:CGPoint{get set}
}

extension Cell {
  func setup(with world:World){
    self.world = world
    self.growth = { () in
      self.appendCell(rotate:  CGFloat.random(in: 0...5))
      self.growth = {() in }
    }

    self.physicsBody = SKPhysicsBody.init(circleOfRadius: cellRadius)
    physicsBody!.categoryBitMask = PhysicsCategory.Cell
    physicsBody!.collisionBitMask = PhysicsCategory.Edge | PhysicsCategory.Cell

  }
  func update(_ currentTime:TimeInterval){
    energy += 1
    if energy > Self.growthEnergy {
      growth()
      energy -= Self.growthEnergy
    }
    if energy > childCells.count {
      childCells.forEach{$0.energy += 1}
      energy -= childCells.count
    }
    childCells.forEach{$0.update(currentTime)}
  }

  func appendCell(rotate: CGFloat) {
    let length = cellRadius * 3
    let radius = CGFloat.pi / 3
    let spawnPoint = CGPoint(x: self.position.x - length * sin(radius * rotate) , y: self.position.y + length * cos(radius * rotate))

    let childCell = BaseCell.init(circleOfRadius: cellRadius)
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

class BaseCell:SKShapeNode, Cell {
  static let growthEnergy = 10
  var joints:[SKPhysicsJoint] = []
  var energy = 0
  var childCells:[Cell] = []
  var world: World!
  var growth: () -> () = {() in  }
  func work() {}


}

class WallCell {
  static let growthEnergy = 10
  var joints:[SKPhysicsJoint] = []
  var energy = 0
  var childCells:[Cell] = []
  let growthEnergy = 10
  var world: World!
  var growth: () -> () = {() in  }
  func work() {}

}

class GreenCell:SKShapeNode, Cell {
  static let growthEnergy = 10
  var joints:[SKPhysicsJoint] = []
  var energy = 0
  var childCells:[Cell] = []
  let growthEnergy = 10
  var world: World!
  var growth: () -> () = {() in  }
  func work() {}

}

class FootCell {

}

class BreedCell {

}
