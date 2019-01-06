//
//  Cell.swift
//  alife iOS
//
//  Created by hayato.iida on 2019/01/06.
//  Copyright © 2019年 hayato.iida. All rights reserved.
//

import SpriteKit
var nothing = {() in }
typealias BaseCell = SKShapeNode & Cell

protocol Cell: class {
  static var growthEnergy:CGFloat {get}
  static var growthLimit:Int {get}
  static var color:NSColor {get}

  var gene:Gene! {get set}
  var childCells:[Cell] {get set}
  var joints:[SKPhysicsJoint] {get set}
  var energy:CGFloat {get set}
  var world:World! {get set}
  var physicsBody:SKPhysicsBody?{get set}
  var position:CGPoint{get set}
  var growthCount:Int{get set}

  func setup(with world:World, gene: Gene)
  func update(_ currentTime:TimeInterval)
  func work()
  func nextGrowth() -> (()->())
  func death()
}

extension Cell {
  func setup(with world:World, gene:Gene){
    self.world = world
    self.gene = gene

    self.physicsBody = SKPhysicsBody.init(circleOfRadius: cellRadius)
    physicsBody!.categoryBitMask = PhysicsCategory.Cell
    physicsBody!.collisionBitMask = PhysicsCategory.Edge | PhysicsCategory.Cell

  }
  func update(_ currentTime:TimeInterval){
    work()
    gene.ticket += 1
    energy -= 0.1
    if gene.canGrowth {
      if energy >= Self.growthEnergy && growthCount < Self.growthLimit && gene.alive {
        growthCount += 1
        nextGrowth()()
        energy -= Self.growthEnergy
      }
    }
    if energy > CGFloat(childCells.count) {
      childCells.forEach{
        if $0.energy > self.energy + 1.1 {
          self.energy += 1
          $0.energy -= 1.1
        }
        if self.energy > $0.energy + 1.1 {
          $0.energy += 1
          self.energy -= 1.1
        }
      }
    }
    childCells.forEach{$0.update(currentTime)}
    if energy <= 0 || gene.alive {
      death()
    }
  }

  func appendCell(childCell: SKShapeNode, rotate: CGFloat) {
    let length = cellRadius * 3
    let radius = CGFloat.pi / 3
    let spawnPoint = CGPoint(x: self.position.x - length * sin(radius * rotate) , y: self.position.y + length * cos(radius * rotate))

    childCell.position = spawnPoint

    childCell.fillColor = Self.color
    childCells.append(childCell as! Cell)
    world.addChild(childCell)

    let joint = SKPhysicsJointLimit.joint(withBodyA: physicsBody!, bodyB: childCell.physicsBody!,
                                          anchorA: position,anchorB: childCell.position)
    self.joints.append(joint)
    world.physicsWorld.add(joint)
  }

  func death() {

  }
}

class DebugCell:SKShapeNode, Cell {
  static var growthLimit: Int = 6
  static var color = NSColor.white
  var growthCount: Int = 0
  static let growthEnergy:CGFloat = 10
  var gene: Gene!
  var joints:[SKPhysicsJoint] = []
  var energy:CGFloat = 10
  var childCells:[Cell] = []
  var world: World!
  var growth: () -> () = {() in  }
  func work() {}

  func nextGrowth()->(()->()) {
    return {() in
      let childCell = DebugCell.init(circleOfRadius: cellRadius)
      childCell.setup(with: self.world, gene:self.gene)
      childCell.energy = DebugCell.growthEnergy/2
      self.appendCell(childCell: childCell,rotate:  CGFloat.random(in: 0...5))
    }
  }
}

class WallCell:SKShapeNode, Cell {
  static var growthLimit: Int = 6
  static var color = NSColor.gray
  var growthCount: Int = 0
  var gene: Gene!
  static let growthEnergy:CGFloat = 10
  var joints:[SKPhysicsJoint] = []
  var energy:CGFloat = 0
  var childCells:[Cell] = []
  var world: World!
  func work() {
    print(energy)
  }

  func nextGrowth()->(()->()) {
    return {() in
      print("wall growth")
      let childCell = BreedCell.init(circleOfRadius: cellRadius)
      childCell.setup(with: self.world, gene:self.gene)
      childCell.energy = BreedCell.growthEnergy/2
      self.appendCell(childCell: childCell,rotate:  CGFloat.random(in: 0...5))
    }
  }
}

class GreenCell:SKShapeNode, Cell {
  static var growthLimit: Int = 6
  static var color = NSColor.green
  var growthCount: Int = 0
  var gene: Gene!
  static let growthEnergy:CGFloat = 10
  var joints:[SKPhysicsJoint] = []
  var energy:CGFloat = 0
  var childCells:[Cell] = []
  var world: World!

  func work() {
    energy += 10 // TODO: 場所による差をつける
  }

  func nextGrowth()->(()->()) {
    return {() in
      print("green growth")
      let childCell = WallCell.init(circleOfRadius: cellRadius)
      childCell.setup(with: self.world, gene:self.gene)
      childCell.energy = WallCell.growthEnergy/2
      self.appendCell(childCell: childCell,rotate:  CGFloat.random(in: 0...5))
    }
  }
}

class FootCell {

}

class BreedCell: BaseCell {
  static var growthLimit: Int = 6
  static var color = NSColor.orange
  var growthCount: Int = 0
  var gene: Gene!
  static let growthEnergy:CGFloat = 10
  var joints:[SKPhysicsJoint] = []
  var energy:CGFloat = 0
  var childCells:[Cell] = []
  var world: World!

  var workEnergy:CGFloat = 100
  func work() {
    if energy > workEnergy{
      // 子供つくる
      print("breeding")
      let cell = GreenCell.init(circleOfRadius: cellRadius)
      cell.setup(with: world, gene:Gene())
      cell.position = position
      cell.energy = workEnergy
      energy -= workEnergy
      world.appendLife(cell:cell)
    }
  }

  func nextGrowth()->(()->()) {
    return nothing
  }
}

class Gene {
  var lifespan = 10000
  var ticket = 0
  var alive:Bool {
    return ticket < lifespan
  }
  var canGrowth:Bool {
    // 10 turn over
    return ticket > 10
  }
}
