//
//  GameViewController.swift
//  TestMetal2
//
//  Created by Pål Forsberg on 2016-01-04.
//  Copyright © 2016 Pål Forsberg. All rights reserved.
//

import UIKit
import Metal
import MetalKit
import simd


struct Uniforms
{
    let modelViewProjectionMatrix : float4x4
    let modelViewMatrix : float4x4
    let normalMatrix : float3x3
};

class GameViewController:UIViewController, ModelDelegate {
    
    
    var angularVelocity : CGPoint = CGPointZero
    var angle : CGPoint = CGPointZero
    
    var renderer : Renderer = Renderer()
    var vertexBuffer : MTLBuffer?
    var indexBuffer : MTLBuffer?
    var uniformBuffer : MTLBuffer?
    var displayLink : CADisplayLink?
    
    var models = [Model]()
    
    var global_model : OBJModel? = nil
    override func viewDidLoad() {
        
        super.viewDidLoad()
        renderer.metalLayer = self.view.layer as? CAMetalLayer
        renderer.initilize()
        renderer.vertexFunctionName = "vertex_main"
        renderer.fragmentFunctionName = "fragment_main"
        
        
        
        let panner = UIPanGestureRecognizer(target: self, action: Selector("panned:"))
        self.view.addGestureRecognizer(panner)
        
        addModel("spot")
        addModel("plane")
    }
    
    func addModel(name : String){
        let m = Model(name: name, delegate: self)
        models.append(m)
    }
    
    override func viewDidAppear(animated: Bool) {
        self.displayLink = CADisplayLink(target: self, selector: "displayDidLinkFire:")
        self.displayLink?.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSRunLoopCommonModes)
    }
    
    override func viewWillDisappear(animated: Bool) {
        self.displayLink?.invalidate()
        self.displayLink = nil
    }
    
    func displayDidLinkFire(dLink : CADisplayLink){
        self.redraw()
    }
    
    func panned(panner : UIPanGestureRecognizer){
        let velo = panner.velocityInView(self.view)
        let translation = panner.translationInView(self.view)
        self.angularVelocity = CGPoint(x: velo.x * 0.01, y: velo.y * 0.01)
        models[0].moveBy(float3(Float(translation.x) * 0.01, Float(-translation.y) * 0.01, 0))
        panner.setTranslation(CGPointZero, inView: self.view)
    }
    

    func updateUniforms(modelMatrix : float4x4){
        
//        let X_AXIS = float3(1,0,0)
//        let Y_AXIS = float3(0,1,0)
        
//        var modelMatrix = Identity()
//        modelMatrix = Rotation(Y_AXIS, angle: Float(-self.angle.x)) * modelMatrix
//        modelMatrix = Rotation(X_AXIS, angle: Float(-self.angle.y)) * modelMatrix
        
        
        var viewMatrix = GameViewController.Identity()
        viewMatrix[3].z = -2
        
        let near : Float = 1
        let far : Float = 100
        let aspect = Float(self.view.bounds.size.width / self.view.bounds.size.height)
        let projectionMatrix = perspecitveProjection(aspect, fovy: DegToRad(75), near: near, far: far)

        let modelView = viewMatrix * modelMatrix
        let modelViewProj = projectionMatrix * modelView
        var normalMatrix = float3x3()
        normalMatrix[0] = modelView[0].xyz()
        normalMatrix[1] = modelView[1].xyz()
        normalMatrix[2] = modelView[2].xyz()
        normalMatrix = normalMatrix.inverse.transpose
        
        var uniform = Uniforms(modelViewProjectionMatrix: modelViewProj, modelViewMatrix: modelView, normalMatrix: normalMatrix)
        self.uniformBuffer = self.renderer.newBufferWithBytes(&uniform, length: sizeof(Uniforms))
    }
    
    func redraw(){
        self.angle = CGPointMake(self.angle.x + self.angularVelocity.x * 0.1,
            self.angle.y + self.angularVelocity.y * 0.1);
        
        
        self.renderer.startFrame()
        for m in models {
            self.updateUniforms(m.transform)
            self.renderer.drawTrianglesWithInterleavedBuffer(m.vertexBuffer!, indexBuffer: m.indexBuffer!, uniformBuffer: self.uniformBuffer!, indexCount:m.indexBuffer!.length / sizeof(IndexType), texture: m.texture)
        }
        
        self.renderer.endFrame()
        
    }
    
    class func Identity() -> float4x4 {
        return float4x4(diagonal: float4(1,1,1,1))
    }
    
    func perspecitveProjection(aspect : Float, fovy : Float, near : Float, far : Float) -> float4x4{
        let yScale = 1 / tan(fovy * 0.5)
        let xScale = yScale / aspect
        let zRange = far - near
        let zScale = -(far + near) / zRange
        let wzScale = -2 * far * near / zRange
        
        
        var matrix = float4x4(diagonal: float4(xScale, yScale, zScale, 0))
        matrix[3][2] = -1
        matrix[2][3] = wzScale
        return matrix
        
    }
    
    func DegToRad(deg : Float) -> Float{
        return deg * (Float(M_PI) / 180.0);
    }
    
    func Rotation(axis : float3, angle : Float) ->float4x4 {
        let c = cos(angle);
        let s = sin(angle);

        var X : float4 = float4()
        X.x = axis.x * axis.x + (1 - axis.x * axis.x) * c;
        X.y = axis.x * axis.y * (1 - c) - axis.z*s;
        X.z = axis.x * axis.z * (1 - c) + axis.y * s;
        X.w = 0.0;

        var Y : float4 = float4()
        Y.x = axis.x * axis.y * (1 - c) + axis.z * s;
        Y.y = axis.y * axis.y + (1 - axis.y * axis.y) * c;
        Y.z = axis.y * axis.z * (1 - c) - axis.x * s;
        Y.w = 0.0;

        var Z : float4 = float4()
        Z.x = axis.x * axis.z * (1 - c) - axis.y * s;
        Z.y = axis.y * axis.z * (1 - c) + axis.x * s;
        Z.z = axis.z * axis.z + (1 - axis.z * axis.z) * c;
        Z.w = 0.0;

        var W : float4 = float4()
        W.x = 0.0;
        W.y = 0.0;
        W.z = 0.0;
        W.w = 1.0;

        let mat = float4x4([X,Y,Z,W]);
        return mat;
    }
    
    func wantsRenderer() -> Renderer {
        return self.renderer
    }
    
}

extension float4 {
    func xyz()->float3 {
        return float3(x, y, z)
    }
}

