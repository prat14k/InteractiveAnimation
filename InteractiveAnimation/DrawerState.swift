//
//  DrawerState.swift
//  InteractiveAnimation
//
//  Created by Prateek Sharma on 6/12/18.
//  Copyright © 2018 Prateek Sharma. All rights reserved.
//

import UIKit


enum DrawerState {
    case expanded
    case collapsed
    
    var cornerRadius: CGFloat  { return self == .expanded ? 15 : 0 }
}

prefix func !(_ state: DrawerState) -> DrawerState {
    return state == DrawerState.expanded ? .collapsed : .expanded
}
