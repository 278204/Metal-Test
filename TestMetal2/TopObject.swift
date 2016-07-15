//
//  TopObject.swift
//  TestMetal2
//
//  Created by Pål Forsberg on 2016-02-01.
//  Copyright © 2016 Pål Forsberg. All rights reserved.
//

import Foundation
import simd

class TopObject : Object {
    
    override init(name: String, texture: String, fragmentType: FragmentType) {
        super.init(name: name, texture: texture, fragmentType: fragmentType)
        self.collision_side_bit = 0b0111
    }
    
    override func modelDidIntersect(model: Model, side: Direction, penetration_vector: float2) -> Bool{
//        print("model \(model.rect.origin.y) \(model.current_rect.origin.y) self \(self.rect.max.y)")
        //WARNING, penetration vector doesn't work?
        if model.current_rect.origin.y >= self.current_rect.max.y && model.velocity.y <= 0 && (self.collision_side_bit & 0b1000 == 0) {
            
            model.rect.origin += penetration_vector
            return true
        }
        return false
    }
}
