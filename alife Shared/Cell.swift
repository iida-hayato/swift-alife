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

  var childCells:         [String: Cell] { get set }
  var joints:             [SKPhysicsJoint] { get set }
  var energy:             CGFloat { get set }
  var world:              World! { get set }
  var life:               Life! { get set }
  var cost:               CGFloat { get set }
  var energyMoveCapacity: CGFloat { get set }
  var coreStatus:         CoreStatus! { get set }

  var position:    CGPoint { get set }
  var fillColor:   SCNColor { get set }
  var strokeColor: SCNColor { get set }
  func removeFromParent()
  var name: String? { get set }

  func setup(with world: World, life: Life, coreStatus: CoreStatus, death: @escaping () -> ())
  func update(_ currentTime: TimeInterval)
  func work()
  func nextGrowth()
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
    energy -= cost
    if canGrowth() {
      growth()
    }
    moveEnergy()
    if canKill() {
      kill()
    }
  }

  private func moveEnergy() {
    let moveCost: CGFloat = 1
    childCells.shuffled().forEach {
      let delta = self.energy - $0.value.energy
      guard abs(delta) > 1 + moveCost else {
        return
      }
      let moveValue          = delta / 2
      if moveValue > 0 {
        self.energy -= min(moveValue, $0.value.energyMoveCapacity) + moveCost
        $0.value.energy += min(moveValue, $0.value.energyMoveCapacity)
      } else {
        self.energy -= max(moveValue, -self.energyMoveCapacity)
        $0.value.energy += max(moveValue, -self.energyMoveCapacity) - moveCost
      }
    }
  }

  private func canKill() -> Bool { return energy <= 0 || !life.gene.alive }

  private func growth() {
    nextGrowth()
    self.coreStatus.growthCount += 1
    energy -= Self.growthEnergy + self.coreStatus.childCellInitialEnergy
  }

  private func canGrowth() -> Bool { return life.gene.canGrowth && energy >= Self.growthEnergy + self.coreStatus.childCellInitialEnergy && self.coreStatus.growthCount < self.coreStatus.growthLimit && life.gene.alive }

  func adjustRotatedPoint(rotate: CGFloat, distance: CGFloat = 1, baseRadian: CGFloat = CGFloat.pi / 3) -> CGPoint {
    let radian = radianBetween(from: self.position, to: world.sun.position)
    return CGPoint(x: distance * (cos(baseRadian * rotate + radian)),
                   y: distance * (sin(baseRadian * rotate + radian)))
  }

  func appendCell(childCell: SKShapeNode, rotate: CGFloat) {
    let length       = cellRadius * 2
    let rotatedPoint = adjustRotatedPoint(rotate: rotate + 0.01 * CGFloat(coreStatus.growthCount), distance: length)
    let spawnPoint   = CGPoint(x: self.position.x + rotatedPoint.x, y: self.position.y + rotatedPoint.y)

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
  func nextGrowth() {
    let code = self.life.gene.nextCode(by: self.coreStatus.genePosition, growthCount: self.coreStatus.growthCount)
    if code.count < self.life.gene.primeGeneLength {
      return
    }
    guard let childCell = { () -> Cell? in
      switch code[0] % 5 {
      case 0:
        return WallCell.init(circleOfRadius: cellRadius)
      case 1:
        return GreenCell.init(circleOfRadius: cellRadius)
      case 2:
        return BreedCell.init(circleOfRadius: cellRadius)
      case 3:
        return TankCell.init(circleOfRadius: cellRadius)
      case 4:
        return FootCell.init(circleOfRadius: cellRadius)
      default:
        return nil
      }
    }() else {
      return
    }
    childCell.setup(with: self.world, life: self.life, coreStatus: CoreStatus(with: code)) { [weak self] in
      if let name = childCell.name {
        self?.childCells.removeValue(forKey: name)
      }
    }
    childCell.energy += self.coreStatus.childCellInitialEnergy
    self.appendCell(childCell: childCell as! SKShapeNode, rotate: childCell.coreStatus.growthRotation)
  }

}

class CoreStatus {
  static var MaxGrowthLimit = 6
  var code:                   [UInt8]
  var growthCount:            Int = 0
  var genePosition:           Int
  var growthLimit:            Int
  var growthRotation:         CGFloat
  var childCellInitialEnergy: CGFloat

  init(with geneCode: [UInt8]) {
    self.code = geneCode
    self.genePosition = Int(geneCode[1])
    self.growthLimit = Int(geneCode[2]) % (CoreStatus.MaxGrowthLimit + 1)
    self.growthRotation = CGFloat(geneCode[3])
    self.childCellInitialEnergy = CGFloat(geneCode[4])
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
  var cost:               CGFloat = 1
  var energyMoveCapacity: CGFloat = 5

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
  var cost:               CGFloat = 3
  var energyMoveCapacity: CGFloat = 5

  func work() {
    let distance = distanceBetween(from: self.position, to: world.sun.position)
    energy += { () -> CGFloat in
      let MaxGenerateEnergy: CGFloat = 20
      if distance <= 1 {
        return MaxGenerateEnergy
      }
      return max(MaxGenerateEnergy * world.sun.power - (distance * 0.05), 0)
    }()
  }

}

class FootCell:BaseCell {
  var death: (() -> ())!

  static var color = SCNColor.blue
  var coreStatus: CoreStatus!
  static let growthEnergy: CGFloat = 10
  var joints:     [SKPhysicsJoint] = []
  var energy:     CGFloat          = 0
  var childCells: [String: Cell]   = [:]
  weak var world: World!
  weak var life:  Life!
  var cost:               CGFloat = 1
  var energyMoveCapacity: CGFloat = 5

  var property: CellProperty!
  class CellProperty {
    var velocityRotation: CGFloat
    var velocityPower:    CGFloat

    init(with code: [UInt8]) {
      self.velocityRotation = CGFloat(code[5])
      self.velocityPower = CGFloat(code[6])
    }
  }
  func work() {
    if self.property == nil {
      property = CellProperty(with: coreStatus.code)
    }
    if energy > self.property.velocityPower / 10 + cost {
      energy -= property.velocityPower / 10
      let velocity: CGFloat = property.velocityPower
      let rotate:   CGFloat = property.velocityRotation

      let rotatedPoint = adjustRotatedPoint(rotate: rotate, distance: velocity)
      physicsBody!.velocity = CGVector.init(dx: rotatedPoint.x, dy: rotatedPoint.y)
    }
  }

}

class TankCell: BaseCell {
  var death: (() -> ())!

  static var color = SCNColor.yellow
  var coreStatus: CoreStatus!
  static let growthEnergy: CGFloat = 10
  var joints:     [SKPhysicsJoint] = []
  var energy:     CGFloat          = 0
  var childCells: [String: Cell]   = [:]
  weak var world: World!
  weak var life:  Life!
  var cost:               CGFloat = 1
  var energyMoveCapacity: CGFloat = 50

  func work() {}

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
  var cost:               CGFloat = 2
  var energyMoveCapacity: CGFloat = 5

  var property: BreedCellProperty!

  class BreedCellProperty {
    var childLifeInitialEnergy:    CGFloat
    var childLifeVelocityRotation: CGFloat
    var childLifeVelocityPower:    CGFloat

    init(with code: [UInt8]) {
      self.childLifeInitialEnergy = CGFloat(code[5])
      self.childLifeVelocityRotation = CGFloat(code[6])
      self.childLifeVelocityPower = CGFloat(code[7])
    }
  }

  func work() {
    if self.property == nil {
      property = BreedCellProperty(with: coreStatus.code)
    }
    if energy > property.childLifeInitialEnergy + GreenCell.growthEnergy + cost {
      // 子供つくる
      let cell = GreenCell.init(circleOfRadius: cellRadius)
      let life = Life.init(world: self.world, cell: cell, gene: Gene(code: self.life.gene.mutatedCode))
      print(self.life.gene.code)
      cell.position = position
      cell.energy = property.childLifeInitialEnergy
      energy -= property.childLifeInitialEnergy + GreenCell.growthEnergy
      world.appendLife(life: life, cell: cell)

      let velocity: CGFloat = property.childLifeVelocityPower
      let rotate:   CGFloat = property.childLifeVelocityRotation

      let rotatedPoint = adjustRotatedPoint(rotate: rotate, distance: velocity)
      cell.physicsBody!.velocity = CGVector.init(dx: rotatedPoint.x, dy: rotatedPoint.y)
      

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
    // Cellの種類,分裂セルのGene参照先,分裂数,分裂方向,分裂細胞の初期エネルギー
    // ,Breed:子供の初期エネルギー,子供の射出方向,子供の射出威力
    // ,Foot:移動方向,移動の出力
    1, 1, 6, 3, 10, 0, 11, 100, 0, 0, // rootCell
    4, 7, 1, 3, 10, 0, 12, 100, 0, 0, // rootCell.child[0] == Cell[1]
    0, 7, 1, 3, 10, 0, 13, 100, 0, 0, // rootCell.child[1]
    0, 7, 1, 3, 10, 0, 14, 100, 0, 0, // rootCell.child[2]
    0, 7, 1, 3, 10, 0, 15, 100, 0, 0, // rootCell.child[3]
    0, 7, 1, 3, 10, 0, 16, 100, 0, 0, // rootCell.child[4]
    3, 7, 1, 3, 10, 0, 17, 100, 0, 0, // rootCell.child[5]
    2, 0, 0, 3, 10, 0, 18, 10, 0, 0, // Cell[1].child[0]
    0, 0, 0, 3, 10, 0, 19, 100, 0, 0, // Cell[1].child[1]
    0, 0, 0, 3, 10, 0, 20, 100, 0, 0, // Cell[1].child[2]
    0, 0, 0, 3, 10, 0, 21, 100, 0, 0, // Cell[1].child[3]
    0, 0, 0, 3, 10, 0, 22, 100, 0, 0, // Cell[1].child[4]
    0, 0, 0, 3, 10, 0, 23, 100, 0, 0, // Cell[1].child[5]
  ]
  var code: [UInt8]

  init(code: [UInt8]) {
    self.code = code
  }

  var lifespan = 1000
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
