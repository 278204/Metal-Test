//
//  GridObject.swift
//  TestMetal2
//
//  Created by Pål Forsberg on 2016-02-06.
//  Copyright © 2016 Pål Forsberg. All rights reserved.
//

import Foundation
import simd

class GridObject : Object {
    init(){
        super.init(name: "Grid", texture: "Texture2.png", fragmentType: FragmentType.Texture)
        self.rect.origin = float2(0,0)
    }
}