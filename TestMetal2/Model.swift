//
//  Model.swift
//  TestMetal2
//
//  Created by Pål Forsberg on 2016-01-04.
//  Copyright © 2016 Pål Forsberg. All rights reserved.
//

import Foundation
import Metal
import simd

class Model{
    
    let model_key : String
    var transform : float4x4
    var position : float3 = float3(0,0,0)
    var hitbox  : Box?
    var uniformBuffer : MTLBuffer?
    
    init(name : String){
        transform = Matrix.Identity()
        model_key = name
    }
    
    func moveBy(offset : float3) {
        position.x += offset.x
        position.y += offset.y
        position.z += offset.z
        transform[3].x = position.x
        transform[3].y = position.y
        transform[3].z = position.z
    }
}
