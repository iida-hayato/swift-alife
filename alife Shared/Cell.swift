//
//  Cell.swift
//  alife iOS
//
//  Created by hayato.iida on 2019/01/06.
//  Copyright © 2019年 hayato.iida. All rights reserved.
//

import SpriteKit

var nothing = { () in }
typealias BaseCell = SKShapeNode & Cell

protocol Cell: class {
  static var growthEnergy: CGFloat { get }
  static var growthLimit:  Int { get }
  static var color:        SCNColor { get }

  var childCells:  [String: Cell] { get set }
  var joints:      [SKPhysicsJoint] { get set }
  var energy:      CGFloat { get set }
  var world:       World! { get set }
  var life:        Life! { get set }
  var growthCount: Int { get set }
  var growthOrder: Int {get set}

  var position:    CGPoint { get set }
  var fillColor:   SCNColor { get set }
  var strokeColor: SCNColor { get set }
  func removeFromParent()
  var name: String? { get set }

  func setup(with world: World, life: Life, death: @escaping () -> ())
  func update(_ currentTime: TimeInterval)
  func work()
  func nextGrowth() -> (() -> ())
  var death: (() -> ())! { get set }
}

extension Cell {
  func setup(with world: World, life: Life, death: @escaping () -> ()) {
    self.world = world
    self.life = life
    self.death = death
    self.growthOrder = life.growthCount
    life.growthCount += 1

    let name = UUID.init().uuidString
    self.name = name
    life.cells[name] = self

    if let node = self as? SKShapeNode {
      let physicsBody = SKPhysicsBody.init(circleOfRadius: cellRadius)
      physicsBody.categoryBitMask = PhysicsCategory.Cell
      physicsBody.collisionBitMask = PhysicsCategory.Edge | PhysicsCategory.Cell

      let temp: CGFloat = 1.0
      physicsBody.friction = temp
      physicsBody.mass = temp
      physicsBody.density = temp

      node.physicsBody = physicsBody
    }


    fillColor = Self.color
    strokeColor = life.color

  }

  func update(_ currentTime: TimeInterval) {
    work()
    energy -= 0.1
    if life.gene.canGrowth {
      if energy >= Self.growthEnergy && growthCount < Self.growthLimit && life.gene.alive {
        growthCount += 1
        life.growthCount += 1
        nextGrowth()()
        energy -= Self.growthEnergy
      }
    }
    if energy > CGFloat(childCells.count) {
      childCells.forEach {
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
    if energy <= 0 || !life.gene.alive {
      kill()
    }
  }

  func appendCell(childCell: SKShapeNode, rotate: CGFloat) {
    let length     = cellRadius * 2
    let radius     = CGFloat.pi / 3
    let spawnPoint = CGPoint(x: self.position.x - length * sin(radius * rotate), y: self.position.y + length * cos(radius * rotate))

    childCell.position = spawnPoint
    if let name = childCell.name {
      childCells[name] = (childCell as! Cell)
    }
    world.addChild(childCell)

    if let node = self as? SKShapeNode {
      let joint = SKPhysicsJointSpring.joint(withBodyA: node.physicsBody!, bodyB: childCell.physicsBody!,
                                             anchorA: position, anchorB: childCell.position)
      self.joints.append(joint)
      world.physicsWorld.add(joint)
    }
    else {
      fatalError()
    }
  }

  func kill() {
    death()

    joints.forEach { self.world.physicsWorld.remove($0) }
    joints.removeAll()
    removeFromParent()
    life.cells.removeValue(forKey: name!)
  }
}

class DebugCell: SKShapeNode, Cell {
  var death: (() -> ())!

  static var growthLimit: Int = 6
  static var color            = SCNColor.white
  var growthCount: Int = 0
  static let growthEnergy: CGFloat = 10

  var joints:     [SKPhysicsJoint] = []
  var energy:     CGFloat          = 10
  var childCells: [String: Cell]   = [:]
  var growthOrder: Int = 0
  weak var world: World!
  weak var life:  Life!
  var growth: () -> () = { () in }

  func work() {}


  func nextGrowth() -> (() -> ()) {
    return { () in
      let childCell = DebugCell.init(circleOfRadius: cellRadius)
      childCell.setup(with: self.world, life: self.life) { [weak self] in
        if let name = childCell.name {
          self?.childCells.removeValue(forKey: name)
        }
      }
      childCell.energy = DebugCell.growthEnergy / 2
      self.appendCell(childCell: childCell, rotate: CGFloat.random(in: 0...5))
    }
  }
}

class WallCell: SKShapeNode, Cell {
  var death: (() -> ())!

  static var growthLimit: Int = 1
  static var color            = SCNColor.gray
  var growthCount: Int = 0
  static let growthEnergy: CGFloat = 10
  var joints:     [SKPhysicsJoint] = []
  var energy:     CGFloat          = 0
  var childCells: [String: Cell]   = [:]
  var growthOrder: Int = 0
  weak var world: World!
  weak var life:  Life!

  func work() {}

  func nextGrowth() -> (() -> ()) {
    return { () in
      let childCell = BreedCell.init(circleOfRadius: cellRadius)
      childCell.setup(with: self.world, life: self.life) { [weak self] in
        if let name = childCell.name {
          self?.childCells.removeValue(forKey: name)
        }
      }
      childCell.energy = BreedCell.growthEnergy / 2
      self.appendCell(childCell: childCell, rotate: CGFloat.random(in: 0...5))
    }
  }
}

class GreenCell: SKShapeNode, Cell {
  var death: (() -> ())!

  static var growthLimit: Int = 5
  static var color            = SCNColor.green
  var growthCount: Int = 0
  static let growthEnergy: CGFloat = 10
  var joints:     [SKPhysicsJoint] = []
  var energy:     CGFloat          = 0
  var childCells: [String: Cell]   = [:]
  var growthOrder: Int = 0
  weak var world: World!
  weak var life:  Life!

  func work() {
    let distance = distanceBetween(first: self.position, second: CGPoint.zero)
    energy += { () -> CGFloat in
      let MaxGenerateEnergy: CGFloat = 10
      if distance <= 1 {
        return MaxGenerateEnergy
      }
      return MaxGenerateEnergy / (distance * 0.05)
    }()
  }

  func nextGrowth() -> (() -> ()) {
    return { () in
      let childCell = WallCell.init(circleOfRadius: cellRadius)
      childCell.setup(with: self.world, life: self.life) { [weak self] in
        if let name = childCell.name {
          self?.childCells.removeValue(forKey: name)
        }
      }
      childCell.energy = WallCell.growthEnergy / 2
      self.appendCell(childCell: childCell, rotate: CGFloat.random(in: 0...5))
    }
  }
}

class FootCell {

}

class BreedCell: BaseCell {
  var death: (() -> ())!

  static var growthLimit: Int = 6
  static var color            = SCNColor.orange
  var growthCount: Int = 0
  static let growthEnergy: CGFloat = 10
  var joints:     [SKPhysicsJoint] = []
  var energy:     CGFloat          = 0
  var childCells: [String: Cell]   = [:]
  var growthOrder: Int = 0
  weak var world: World!
  weak var life:  Life!

  var workEnergy: CGFloat = 10

  func work() {
    if energy > workEnergy {
      // 子供つくる
      let cell = GreenCell.init(circleOfRadius: cellRadius)
      let life = Life.init(world: self.world, cell: cell, gene: Gene())
      cell.position = position
      cell.energy = workEnergy
      energy -= workEnergy
      world.appendLife(life: life, cell: cell)

      let velocity: CGFloat = 3.0
      let radius     = CGFloat.pi / 3
      let rotate = CGFloat.random(in: 0...5)

      let x = (self.position.x - sin(radius * rotate)) * velocity
      let y = (self.position.y + cos(radius * rotate)) * velocity

      cell.physicsBody!.velocity = CGVector.init(dx: x, dy: y)
    }
  }

  func nextGrowth() -> (() -> ()) {
    return nothing
  }
}

class Gene {
  var code : [UInt8] = [
    0,0,0,0,0,0,
    0,0,0,0,0,0,
    0,0,0,0,0,0,
    0,0,0,0,0,0,
    ]

  var lifespan = 80
  var ticket   = 0
  var alive: Bool {
    return ticket < lifespan
  }
  var canGrowth: Bool {
    // 10 turn over
    return ticket > 10
  }
}

func distanceBetween(first: CGPoint, second: CGPoint) -> CGFloat {
  return CGFloat(hypotf(Float(second.x - first.x), Float(second.y - first.y)));
}

let cellRadius: CGFloat = 10

class Life {
  var cells: [String: Cell] = [:]
  var gene:  Gene
  var color: SCNColor
  var growthCount:Int = 0
  unowned let world: World
  let name: String
  var rootCell: Cell

  init(world: World, cell: Cell, gene: Gene) {
    self.world = world
    self.gene = gene
    self.name = UUID().uuidString
    self.color = SCNColor.init(red: CGFloat(drand48()), green: CGFloat(drand48()), blue: CGFloat(drand48()), alpha: 1.0)
    self.rootCell = cell
  }

  func update(_ currentTime: TimeInterval) {
    gene.ticket += 1
    cells.forEach { $0.value.update(currentTime) }
    if !gene.alive {
      cells.forEach { $0.value.kill() }
      cells.removeAll()
      world.lives.removeValue(forKey: name)
    }
  }
}
