//
// Created by hayato.iida on 2019-01-11.
// Copyright (c) 2019 hayato.iida. All rights reserved.
//

import SpriteKit

func distanceBetween(from: CGPoint, to: CGPoint) -> CGFloat {
  return CGFloat(hypotf(Float(to.x - from.x), Float(to.y - from.y)));
}

func radianBetween(from: CGPoint, to: CGPoint) -> CGFloat {
  return atan2(to.y - from.y, to.x - from.x)
}