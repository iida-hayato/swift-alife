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
  static var color:        SCNColor { get }

  var childCells: [String: Cell] { get set }
  var joints:     [SKPhysicsJoint] { get set }
  var energy:     CGFloat { get set }
  var world:      World! { get set }
  var life:       Life! { get set }
  var coreStatus: CoreStatus! { get set }

  var position:    CGPoint { get set }
  var fillColor:   SCNColor { get set }
  var strokeColor: SCNColor { get set }
  func removeFromParent()
  var name: String? { get set }

  func setup(with world: World, life: Life, coreStatus: CoreStatus, death: @escaping () -> ())
  func update(_ currentTime: TimeInterval)
  func work()
  func nextGrowth() -> (() -> ())
  var death: (() -> ())! { get set }
}

extension Cell {
  func setup(with world: World, life: Life, coreStatus: CoreStatus, death: @escaping () -> ()) {
    self.world = world
    self.life = life
    self.coreStatus = coreStatus
    self.death = death

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
      if energy >= Self.growthEnergy && self.coreStatus.growthCount < self.coreStatus.growthLimit && life.gene.alive {
        nextGrowth()()
        self.coreStatus.growthCount += 1
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
    } else {
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

extension Cell {
  func nextGrowth() -> (() -> ()) {
    let code = self.life.gene.nextCode(by: self.coreStatus.genePosition, growthCount: self.coreStatus.growthCount)
    if code.count < self.life.gene.primeGeneLength {
      return nothing
    }
    switch code[0] % 4 {
    case 0:
      return { () in
        let childCell = WallCell.init(circleOfRadius: cellRadius)
        childCell.setup(with: self.world, life: self.life, coreStatus: CoreStatus(with: code)) { [weak self] in
          if let name = childCell.name {
            self?.childCells.removeValue(forKey: name)
          }
        }
        childCell.energy = WallCell.growthEnergy / 2
        self.appendCell(childCell: childCell, rotate: CGFloat.random(in: 0...5))
      }
    case 1:
      return { () in
        let childCell = WallCell.init(circleOfRadius: cellRadius)
        childCell.setup(with: self.world, life: self.life, coreStatus: CoreStatus(with: code)) { [weak self] in
          if let name = childCell.name {
            self?.childCells.removeValue(forKey: name)
          }
        }
        childCell.energy = WallCell.growthEnergy / 2
        self.appendCell(childCell: childCell, rotate: CGFloat.random(in: 0...5))
      }
    case 2:
      return { () in
        let childCell = BreedCell.init(circleOfRadius: cellRadius)
        childCell.setup(with: self.world, life: self.life, coreStatus: CoreStatus(with: code)) { [weak self] in
          if let name = childCell.name {
            self?.childCells.removeValue(forKey: name)
          }
        }
        childCell.energy = BreedCell.growthEnergy / 2
        self.appendCell(childCell: childCell, rotate: CGFloat.random(in: 0...5))
      }
    default:
      return nothing
    }
  }

}

class CoreStatus {
  static var MaxGrouthLimit = 6
  var growthCount:  Int = 0
  var genePosition: Int
  var growthLimit:  Int

  init(with geneCode: [UInt8]) {
    self.genePosition = Int(geneCode[1])
    self.growthLimit = Int(geneCode[2]) % (CoreStatus.MaxGrouthLimit + 1)
  }
}


class WallCell: SKShapeNode, Cell {
  var death: (() -> ())!


  static var color = SCNColor.gray
  var coreStatus: CoreStatus!
  static let growthEnergy: CGFloat = 10
  var joints:     [SKPhysicsJoint] = []
  var energy:     CGFloat          = 0
  var childCells: [String: Cell]   = [:]
  weak var world: World!
  weak var life:  Life!

  func work() {}

}

class GreenCell: SKShapeNode, Cell {
  var death: (() -> ())!

  static var color = SCNColor.green
  var coreStatus: CoreStatus!
  static let growthEnergy: CGFloat = 10
  var joints:     [SKPhysicsJoint] = []
  var energy:     CGFloat          = 0
  var childCells: [String: Cell]   = [:]
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

}

class FootCell {

}

class BreedCell: BaseCell {
  var death: (() -> ())!

  static var color = SCNColor.orange
  var coreStatus: CoreStatus!
  static let growthEnergy: CGFloat = 10
  var joints:     [SKPhysicsJoint] = []
  var energy:     CGFloat          = 0
  var childCells: [String: Cell]   = [:]
  weak var world: World!
  weak var life:  Life!

  var workEnergy: CGFloat = 10

  func work() {
    if energy > workEnergy {
      // 子供つくる
      let cell = GreenCell.init(circleOfRadius: cellRadius)
      let life = Life.init(world: self.world, cell: cell, gene: Gene(code: self.life.gene.mutatedCode))
      cell.position = position
      cell.energy = workEnergy
      energy -= workEnergy
      world.appendLife(life: life, cell: cell)

      let velocity: CGFloat = 3.0
      let radius            = CGFloat.pi / 3
      let rotate            = CGFloat.random(in: 0...5)

      let x = (self.position.x - sin(radius * rotate)) * velocity
      let y = (self.position.y + cos(radius * rotate)) * velocity

      cell.physicsBody!.velocity = CGVector.init(dx: x, dy: y)
    }
  }
}

class Gene {
  let primeGeneLength = 10
  var cellGeneLength: Int {
    return 6 * self.primeGeneLength
  }
  var geneLength:     Int {
    return Int(code.count / 8)
  }
  static var sampleCode: [UInt8] = [
    // Cellの種類,子セルのGene参照先,子供を生む数
    1, 1, 6, 0, 0, 0, 0, 0, 0, 0, // rootCell
    0, 7, 1, 0, 0, 0, 0, 0, 0, 0, // rootCell.child[0] == Cell[1]
    0, 7, 1, 0, 0, 0, 0, 0, 0, 0, // rootCell.child[1]
    0, 7, 1, 0, 0, 0, 0, 0, 0, 0, // rootCell.child[2]
    0, 7, 1, 0, 0, 0, 0, 0, 0, 0, // rootCell.child[3]
    0, 7, 1, 0, 0, 0, 0, 0, 0, 0, // rootCell.child[4]
    0, 7, 1, 0, 0, 0, 0, 0, 0, 0, // rootCell.child[5]
    2, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Cell[1].child[0]
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Cell[1].child[1]
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Cell[1].child[2]
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Cell[1].child[3]
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Cell[1].child[4]
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Cell[1].child[5]
  ]
  var code: [UInt8]

  init(code: [UInt8]) {
    self.code = code
  }

  var lifespan = 80
  var ticket   = 0
  var alive:     Bool {
    return ticket < lifespan
  }
  var canGrowth: Bool {
    // 10 turn over
    return ticket > 10
  }

  func nextCode(by genePosition: Int, growthCount: Int) -> [UInt8] {
    let geneLoadPosition: Int = ((genePosition + growthCount) * primeGeneLength) % (code.count + 1)
    return self.code.dropFirst(geneLoadPosition).map { $0 }
  }

  // DEBUG
  var mutationRate = 10
  var mutatedCode: [UInt8] {
    return code.map { byte -> UInt8 in
      if UInt8.random(in: 0..<100) <= self.mutationRate {
        return UInt8.random(in: UInt8.min...UInt8.max)
      }
      return byte
    }
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
  unowned let world: World
  let name:     String
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
