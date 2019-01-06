//
//  Cell.swift
//  alife iOS
//
//  Created by hayato.iida on 2019/01/06.
//  Copyright © 2019年 hayato.iida. All rights reserved.
//

import SpriteKit
protocol Cell: class {
  var gene:Gene! {get set}
  var childCells:[Cell] {get set}
  var joints:[SKPhysicsJoint] {get set}
  var energy:Int {get set}
  static var growthEnergy:Int {get}
  var world:World! {get set}
  func setup(with world:World)
  func update(_ currentTime:TimeInterval)
  func work()
  func nextGrowth() -> (()->())
  var physicsBody:SKPhysicsBody?{get set}
  var position:CGPoint{get set}
}

extension Cell {
  func setup(with world:World){
    self.world = world
    self.gene = Gene()

    self.physicsBody = SKPhysicsBody.init(circleOfRadius: cellRadius)
    physicsBody!.categoryBitMask = PhysicsCategory.Cell
    physicsBody!.collisionBitMask = PhysicsCategory.Edge | PhysicsCategory.Cell

  }
  func update(_ currentTime:TimeInterval){
    work()
    gene.ticket += 1
    if gene.ticket < 10 {
      // 生成直後10ターン何もしない
      return
    }
    if energy >= Self.growthEnergy {
      nextGrowth()()
      energy -= Self.growthEnergy
    }
    if energy > childCells.count {
      childCells.forEach{
        if $0.energy > self.energy + 1 {
          self.energy += 1
          $0.energy -= 1
        }
        if self.energy > $0.energy + 1 {
          $0.energy += 1
          self.energy -= 1
        }
      }
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
  var gene: Gene!
  var joints:[SKPhysicsJoint] = []
  var energy = 10
  var childCells:[Cell] = []
  var world: World!
  var growth: () -> () = {() in  }
  func work() {}

  func nextGrowth()->(()->()) {
    return {() in
      self.appendCell(rotate:  CGFloat.random(in: 0...5))
    }
  }
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
  var gene: Gene!
  static let growthEnergy = 10
  var joints:[SKPhysicsJoint] = []
  var energy = 0
  var childCells:[Cell] = []
  let growthEnergy = 10
  var world: World!
  var growth: () -> () = {() in  }

  func work() {
    energy += 1 // TODO: 場所による差をつける
  }

  func nextGrowth()->(()->()) {
    return {() in
      self.appendCell(rotate:  CGFloat.random(in: 0...5))
    }
  }
}

class FootCell {

}

class BreedCell {

}

class Gene {
  var lifespan = 1000
  var ticket = 0
}
