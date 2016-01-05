//
//  Misc.swift
//  TestMetal2
//
//  Created by Pål Forsberg on 2016-01-04.
//  Copyright © 2016 Pål Forsberg. All rights reserved.
//

import Foundation
import simd

struct Uniforms{
    let modelViewProjectionMatrix : float4x4
    let modelViewMatrix : float4x4
    let normalMatrix : float3x3
}


class Matrix{
    class func Identity() -> float4x4 {
        return float4x4(diagonal: float4(1,1,1,1))
    }
}

class Math {
    class func DegToRad(deg : Float) -> Float{
        return deg * (Float(M_PI) / 180.0);
    }
}


extension float4 {
    func xyz()->float3 {
        return float3(x, y, z)
    }
}
extension float4x4 {
    func printOut(){
        print("Matrix:")
        print("\(self.cmatrix.columns.0.x) \(self.cmatrix.columns.1.x) \(self.cmatrix.columns.2.x) \(self.cmatrix.columns.3.x)")
        print("\(self.cmatrix.columns.0.y) \(self.cmatrix.columns.1.y) \(self.cmatrix.columns.2.y) \(self.cmatrix.columns.3.y)")
        print("\(self.cmatrix.columns.0.z) \(self.cmatrix.columns.1.z) \(self.cmatrix.columns.2.z) \(self.cmatrix.columns.3.z)")
        print("\(self.cmatrix.columns.0.w) \(self.cmatrix.columns.1.w) \(self.cmatrix.columns.2.w) \(self.cmatrix.columns.3.w)")
        print("")
    }
}