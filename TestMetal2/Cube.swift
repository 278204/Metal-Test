//
//  Box.swift
//  TestMetal2
//
//  Created by Pål Forsberg on 2016-01-27.
//  Copyright © 2016 Pål Forsberg. All rights reserved.
//

import Foundation


class Cube : Object {

    init(){
        super.init(name: "Cube", texture: "Block_None.png", fragmentType: FragmentType.Texture)
    }
    
    override func collisionSideBitDidChange() {
        self.renderingObject?.setNewTexture(getTexture())
    }
    
    
    
    func getTexture() -> String{
        var string = ""
        if collision_side_bit & 0b1000 == 0 {
            string = string + "Top"
        }
        if collision_side_bit & 0b0010 == 0 {
            string = string + "Bottom"
        }
        if collision_side_bit & 0b0100 == 0 {
            string = string + "Right"
        }
        if collision_side_bit & 0b0001 == 0 {
            string = string + "Left"
        }
        if string.characters.count == 0 {
            string = "None"
        }
        return "Block_\(string).png"
    }
}