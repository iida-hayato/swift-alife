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
  var childCells:[String:Cell] {get set}
  var joints:[SKPhysicsJoint] {get set}
  var energy:CGFloat {get set}
  var world:World! {get set}
  var growthCount:Int{get set}

  var physicsBody:SKPhysicsBody?{get set}
  var position:CGPoint{get set}
  var fillColor:NSColor{get set}
  func removeFromParent()
  var name:String? {get set}

  func setup(with world:World, gene:Gene, death: @escaping ()->())
  func update(_ currentTime:TimeInterval)
  func work()
  func nextGrowth() -> (()->())
  var death: (() -> ())! {get set}
}

extension Cell {
  func setup(with world:World, gene:Gene, death: @escaping ()->()){
    self.world = world
    self.gene = gene
    self.death = death

    self.physicsBody = SKPhysicsBody.init(circleOfRadius: cellRadius)
    physicsBody!.categoryBitMask = PhysicsCategory.Cell
    physicsBody!.collisionBitMask = PhysicsCategory.Edge | PhysicsCategory.Cell

    fillColor = Self.color
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
        if $0.value.energy > self.energy + 1.1 {
          self.energy += 1
          $0.value.energy -= 1.1
        }
        if self.energy > $0.value.energy + 1.1 {
          $0.value.energy += 1
          self.energy -= 1.1
        }
      }
    }
    childCells.forEach{$0.value.update(currentTime)}
    if energy <= 0 || !gene.alive {
      death()
    }
  }

  func appendCell(childCell: SKShapeNode, rotate: CGFloat) {
    let length = cellRadius * 3
    let radius = CGFloat.pi / 3
    let spawnPoint = CGPoint(x: self.position.x - length * sin(radius * rotate) , y: self.position.y + length * cos(radius * rotate))

    childCell.position = spawnPoint
    let name = UUID.init().uuidString
    childCell.name = name
    childCells[name] = (childCell as! Cell)
    world.addChild(childCell)

    let joint = SKPhysicsJointLimit.joint(withBodyA: physicsBody!, bodyB: childCell.physicsBody!,
                                          anchorA: position,anchorB: childCell.position)
    self.joints.append(joint)
    world.physicsWorld.add(joint)
  }

}

class DebugCell:SKShapeNode, Cell {
  var death: (() -> ())!

  static var growthLimit: Int = 6
  static var color = NSColor.white
  var growthCount: Int = 0
  static let growthEnergy:CGFloat = 10
  var gene: Gene!
  var joints:[SKPhysicsJoint] = []
  var energy:CGFloat = 10
  var childCells:[String:Cell] = [:]
  var world: World!
  var growth: () -> () = {() in  }
  func work() {}


  func nextGrowth()->(()->()) {
    return {() in
      let childCell = DebugCell.init(circleOfRadius: cellRadius)
      childCell.setup(with: self.world, gene:self.gene) {
        childCell.joints.forEach {self.world.physicsWorld.remove($0)}
        childCell.joints.removeAll()
        childCell.removeFromParent()
        if let name = childCell.name {
          self.childCells.removeValue(forKey: name)
        }
      }
      childCell.energy = DebugCell.growthEnergy/2
      self.appendCell(childCell: childCell,rotate:  CGFloat.random(in: 0...5))
    }
  }
}

class WallCell:SKShapeNode, Cell {
  var death: (() -> ())!

  static var growthLimit: Int = 1
  static var color = NSColor.gray
  var growthCount: Int = 0
  var gene: Gene!
  static let growthEnergy:CGFloat = 10
  var joints:[SKPhysicsJoint] = []
  var energy:CGFloat = 0
  var childCells:[String:Cell] = [:]
  var world: World!
  func work() {}

  func nextGrowth()->(()->()) {
    return {() in
      let childCell = BreedCell.init(circleOfRadius: cellRadius)
      childCell.setup(with: self.world, gene:self.gene) {
        childCell.joints.forEach {self.world.physicsWorld.remove($0)}
        childCell.joints.removeAll()
        childCell.removeFromParent()
        if let name = childCell.name {
          self.childCells.removeValue(forKey: name)
        }
      }
      childCell.energy = BreedCell.growthEnergy/2
      self.appendCell(childCell: childCell,rotate:  CGFloat.random(in: 0...5))
    }
  }
}

class GreenCell:SKShapeNode, Cell {
  var death: (() -> ())!

  static var growthLimit: Int = 6
  static var color = NSColor.green
  var growthCount: Int = 0
  var gene: Gene!
  static let growthEnergy:CGFloat = 10
  var joints:[SKPhysicsJoint] = []
  var energy:CGFloat = 0
  var childCells:[String:Cell] = [:]
  var world: World!

  func work() {
    let distance = distanceBetween(first: self.position, second: CGPoint.zero)
    energy += {()->CGFloat in
      let MaxGenerateEnergy:CGFloat = 100
      if distance <= 1 {
        return MaxGenerateEnergy
      }
      return MaxGenerateEnergy / (distance * distance)
    }()
  }

  func nextGrowth()->(()->()) {
    return {() in
      let childCell = WallCell.init(circleOfRadius: cellRadius)
      childCell.setup(with: self.world, gene:self.gene) {
        childCell.joints.forEach {self.world.physicsWorld.remove($0)}
        childCell.joints.removeAll()
        childCell.removeFromParent()
        if let name = childCell.name {
          self.childCells.removeValue(forKey: name)
        }
      }
      childCell.energy = WallCell.growthEnergy/2
      self.appendCell(childCell: childCell,rotate:  CGFloat.random(in: 0...5))
    }
  }
}

class FootCell {

}

class BreedCell: BaseCell {
  var death: (() -> ())!

  static var growthLimit: Int = 6
  static var color = NSColor.orange
  var growthCount: Int = 0
  var gene: Gene!
  static let growthEnergy:CGFloat = 10
  var joints:[SKPhysicsJoint] = []
  var energy:CGFloat = 0
  var childCells:[String:Cell] = [:]
  var world: World!

  var workEnergy:CGFloat = 10
  func work() {
    if energy > workEnergy{
      // 子供つくる
      let cell = GreenCell.init(circleOfRadius: cellRadius)
      cell.setup(with: world, gene:Gene()) {
        cell.joints.forEach {self.world.physicsWorld.remove($0)}
        cell.joints.removeAll()
        cell.removeFromParent()
      }
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
  var lifespan = 1000
  var ticket = 0
  var alive:Bool {
    return ticket < lifespan
  }
  var canGrowth:Bool {
    // 10 turn over
    return ticket > 10
  }
}


func distanceBetween(first:CGPoint , second:CGPoint)-> CGFloat {
  return CGFloat(hypotf(Float(second.x - first.x), Float(second.y - first.y)));
}
