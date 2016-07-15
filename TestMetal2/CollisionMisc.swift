//
//  CollisionMisc.swift
//  TestMetal2
//
//  Created by Pål Forsberg on 2016-02-02.
//  Copyright © 2016 Pål Forsberg. All rights reserved.
//

import Foundation
import simd

class ModelContactState {
    var bitmask = UInt8(0)
    
    func setOnLeftWall(){
        bitmask |= 0b0001
    }
    func setOnRightWall(){
        bitmask |= 0b0100
    }
    func setOnGround(){
        bitmask |= 0b0010
    }
    func setOnRoof(){
        bitmask |= 0b1000
    }
    
    func onGround() -> Bool{
        return check_bit(1)
    }
    func onWall() -> Bool {
        return onWallToLeft() || onWallToRight()
    }
    func onWallToRight() -> Bool {
        return check_bit(2)
    }
    func onWallToLeft() -> Bool {
        return check_bit(0)
    }
    func onRoof() -> Bool {
        return check_bit(3)
    }
    
    func squashed() -> Bool {
        return (onWallToLeft() && onWallToRight()) || (onGround() && onRoof())
    }
    
    func check_bit(pos : UInt8) -> Bool{
        return bitmask & (1<<pos) != 0
    }
    func reset(){
        bitmask = 0
    }
}

class CollisionMisc {
    class func checkCollision(inout md_ret : (penetration_vector : float2, side : Direction), bits : UInt8) {
        var reset = false
        switch(md_ret.1){
        case .Top:
            if bits & 0b1000 != 0 {
                reset = true
            }
        case .Right:
            if bits & 0b0100 != 0 {
                reset = true
            }
        case .Left:
            if bits & 0b0001 != 0 {
                reset = true
            }
        case .Bottom:
            if bits & 0b0010 != 0 {
                reset = true
            }
        case .None:
            md_ret.0 = float2(0,0)
        }
        if reset {
            md_ret.1 = .None
            md_ret.0 = float2(0,0)
        }
    }
    
    class func checkCollision(inout md_ret : (h : Float, side : Direction), bits : UInt8) {
        var reset = false
        switch(md_ret.side){
        case .Top:
            if bits & 0b1000 != 0 {
                reset = true
            }
        case .Right:
            if bits & 0b0100 != 0 {
                reset = true
            }
        case .Bottom:
            if bits & 0b0010 != 0 {
                reset = true
            }
        case .Left:
            if bits & 0b0001 != 0 {
                reset = true
            }
        case .None:
            md_ret.0 = Float.infinity
        }
        if reset {
            md_ret.1 = .None
            md_ret.0 = Float.infinity
        }
    }
    
    class func collisionsAgaintsVelocity(inout md_ret : (h : Float, side : Direction), velocity : float2){
        var reset = false
        switch(md_ret.side){
        case .Top:
            if velocity.y > 0 {
                reset = true
            }
        case .Right:
            if velocity.x < 0 {
                reset = true
            }
        case .Left:
            if velocity.x > 0 {
                reset = true
            }
        case .Bottom:
            if velocity.y < 0 {
                reset = true
            }
        case .None:
            md_ret.h = Float.infinity
        }
        if reset {
            md_ret.h = 0
            md_ret.side = .None
        }
    }
}