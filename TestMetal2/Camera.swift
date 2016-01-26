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
    var view_matrix : float4x4
    var projection_matrix = Matrix.Identity()
    var position : float3   {didSet{positionDidSet()}}
    var aspect : Float = 0 {didSet{
        //perspecitveProjection(aspect, fovy: Math.DegToRad(95), near: 1, far: 100)
        }}
    
    init() {
        view_matrix = Matrix.Identity()
        position = float3(0,0,0)
        
    }
    
    func positionDidSet(){
        view_matrix[3].x = position.x
        view_matrix[3].y = position.y
        view_matrix[3].z = position.z
    }
    
    func getUniform(modelMatrix : float4x4) -> Uniforms {

        let modelView = self.view_matrix * modelMatrix
        let modelViewProj = projection_matrix * modelView
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
    
    func setFrustum(right : Float, top : Float){
        projection_matrix = parallelProjection(right: right, left: -right, top: top, bottom: -top, far: 200, near: -200)
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
    
    private func parallelProjection(right r : Float, left l : Float, top t : Float, bottom b : Float, far f : Float, near n : Float) -> float4x4{
        
        var mat = float4x4(diagonal: float4(2/(r - l), 2/(t - b), -2/(f - n), 1))
        mat[3][0] = -(r + l)/(r - l)
        mat[3][1] = -(t + b)/(t - b)
        mat[3][2] = 0.4//(f + n)/(f - n)
        
//        let mat = float4x4(diagonal: float4(1,1,0,1))
        
        
        return mat
    }
    

    
    
}
