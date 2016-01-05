//
//  Camera.swift
//  TestMetal2
//
//  Created by Pål Forsberg on 2016-01-04.
//  Copyright © 2016 Pål Forsberg. All rights reserved.
//

import Foundation
import simd

class Camera {
    var matrix : float4x4
    var position : float3   {didSet{positionDidSet()}}
    var aspect : Float = 0
    
    init() {
        matrix = Matrix.Identity()
        position = float3(0,0,-2)
        positionDidSet()
    }
    
    func positionDidSet(){
        matrix[3].x = position.x
        matrix[3].y = position.y
        matrix[3].z = position.z
    }
    
    func getUniform(modelMatrix : float4x4) -> Uniforms {
        let near : Float = 1
        let far : Float = 100

        let projectionMatrix = perspecitveProjection(aspect, fovy: Math.DegToRad(45), near: near, far: far)
        
        let modelView = self.matrix * modelMatrix
        let modelViewProj = projectionMatrix * modelView
        var normalMatrix = float3x3()
        normalMatrix[0] = modelView[0].xyz()
        normalMatrix[1] = modelView[1].xyz()
        normalMatrix[2] = modelView[2].xyz()
        normalMatrix = normalMatrix.inverse.transpose
        
        let uniform = Uniforms(modelViewProjectionMatrix: modelViewProj, modelViewMatrix: modelView, normalMatrix: normalMatrix)
        
        return uniform
    }
    
    func moveZ(delta : Float){
        moveOffset(float3(0,0,delta))
    }
    
    func moveOffset(offset : float3){
        var pos = position
        pos.x += offset.x
        pos.y += offset.y
        pos.z += offset.z
        position = pos
    }
    
    
    private func perspecitveProjection(aspect : Float, fovy : Float, near : Float, far : Float) -> float4x4{
        let yScale : Float = 1 / tan(fovy * 0.5)
        let xScale : Float = yScale / aspect
        let zRange : Float = far - near
        let zScale : Float = -(far + near) / zRange
        let wzScale : Float = -2 * far * near / zRange
        
        
        var matrix = float4x4(diagonal: float4(xScale, yScale, zScale, 0))
        matrix[3][2] = -1
        matrix[2][3] = wzScale
        return matrix
        
    }
    

    
    
}
