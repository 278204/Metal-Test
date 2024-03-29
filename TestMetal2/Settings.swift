//
//  PhysicsSettings.swift
//  TestMetal2
//
//  Created by Pål Forsberg on 2016-01-05.
//  Copyright © 2016 Pål Forsberg. All rights reserved.
//

import Foundation


class Settings {
    static let gravity = -9.82
    static let gameSpeed : Double = 1.0
    static let gridSize : Float = 2
    static let zoomFactor : Float = 26
    static let drawHitBox = true
    static let showRedObjectsInQuad = false
    static let animations = ["LittleBoy" : ["jump", "resting", "wallSliding", "fall"]]
    static let maxGridPoint = GridPoint(x:100, y:100)
}