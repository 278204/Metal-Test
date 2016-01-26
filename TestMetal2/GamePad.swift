//
//  GamePad.swift
//  TestMetal2
//
//  Created by Pål Forsberg on 2016-01-18.
//  Copyright © 2016 Pål Forsberg. All rights reserved.
//

import Foundation
import GameController


enum Button {
    case A
    case B
    case X
    case Y
    case Left
    case Right
    
    static let allValues = [Button.A, .B, .X, .Y, .Left, .Right]
}

protocol GamePadDelegate {
    func gamePadDidPressButton(button : Button)
    func gamePadDidReleaseButton(button : Button)
}

class GamePad : NSObject{
    static let shared = GamePad()
    var controllerConnected = false
    var gameController : GCController?
    var controller_type : Int = 0
    var delegate : GamePadDelegate?
    var key_map = [Button : Bool]()
    
    override init(){
        super.init()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("controllerStateChanged"), name: GCControllerDidConnectNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("controllerStateChanged"), name: GCControllerDidDisconnectNotification, object: nil)
        GCController.startWirelessControllerDiscoveryWithCompletionHandler { () -> Void in
            self.controllerStateChanged()
        }
        
        for k in Button.allValues {
            key_map[k] = false
        }
        
    }
    
    func checkButtons(){
        guard controllerConnected else {
            print("No controller is connected")
            return
        }
        let profile = self.gameController!.gamepad!
        
        for b in Button.allValues {
            let isPressed = buttonIsPressed(b, profile: profile)
            if isPressed && !key_map[b]! {
                self.delegate?.gamePadDidPressButton(b)
                key_map[b] = true
            } else if !isPressed && key_map[b]! {
                self.delegate?.gamePadDidReleaseButton(b)
                key_map[b] = false
            }
        }
    }
    
    func buttonIsPressed(button : Button, profile : GCGamepad) -> Bool {
        switch(button){
        case .A:
            return profile.buttonA.pressed
        case .B:
            return profile.buttonB.pressed
        case .X:
            return profile.buttonX.pressed
        case .Y:
            return profile.buttonY.pressed
        case .Left:
            return profile.dpad.left.pressed
        case .Right:
            return profile.dpad.right.pressed
        }
        
    }
    func controllerStateChanged(){
        if GCController.controllers().count > 0 {
            print("Controller is connected")
            controllerConnected = true
            self.gameController = GCController.controllers().first!
            if self.gameController?.extendedGamepad == nil {
                controller_type = 1
            } else {
                controller_type = 2
            }
        } else{
            controllerConnected = false
            self.gameController = nil
            controller_type = 0
        }
    }
}