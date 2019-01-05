//
//  Cell.swift
//  alife iOS
//
//  Created by hayato.iida on 2019/01/06.
//  Copyright © 2019年 hayato.iida. All rights reserved.
//

import SpriteKit

class BaseCell:SKShapeNode{
  var joints:[SKPhysicsJoint] = []
  var energy = 0
  var childCells:[BaseCell] = []
  let growthEnergy = 10
  var world: World!
  var growth: () -> () = {() in  }

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

class WallCell {

}

class GreenCell {

}

class FootCell {

}

class BreedCell {

}
