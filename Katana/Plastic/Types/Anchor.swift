//
//  Anchor.swift
//  Katana
//
//  Created by Mauro Bolis on 16/08/16.
//  Copyright © 2016 Bending Spoons. All rights reserved.
//

import UIKit


public struct Anchor: Equatable {
  public enum Kind {
    case Left, Right, CenterX, Top, Bottom, CenterY
  }
  
  let kind: Kind
  let view: PlasticView
  
  init(kind: Kind, view: PlasticView) {
    self.kind = kind
    self.view = view
  }
  
  var coordinate: CGFloat {
    let absoluteOrigin = self.view.absoluteOrigin
    let size = self.view.frame
    
    switch self.kind {
    case .Left:
      return absoluteOrigin.x
    
    case .Right:
      return absoluteOrigin.x + size.width
    
    case .CenterX:
      return absoluteOrigin.x + size.width / 2.0
      
    case .Top:
      return absoluteOrigin.y
      
    case .Bottom:
      return absoluteOrigin.y + size.height
      
    case .CenterY:
      return absoluteOrigin.y + size.height / 2.0
      
    }
  }
  
  public static func ==(lhs: Anchor, rhs: Anchor) -> Bool {
    return lhs.kind == rhs.kind && lhs.view === rhs.view
  }
}
