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

class GameViewController:UIViewController{
    
    var renderer    = Renderer()
    var models      = [Model]()
    var meshes      = [String : Mesh]()
    let camera      = Camera()
    
    var lastScale   = Float(0.0)
    
    var displayLink : CADisplayLink?
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        renderer.metalLayer = self.view.layer as? CAMetalLayer
        renderer.initilize()

        camera.aspect = Float(self.view.frame.size.width / self.view.frame.size.height)
        let panner = UIPanGestureRecognizer(target: self, action: Selector("panned:"))
        self.view.addGestureRecognizer(panner)
        
        let pincher = UIPinchGestureRecognizer(target: self, action: Selector("pinched:"))
        self.view.addGestureRecognizer(pincher)
        
        addModel("Stormtrooper")
        addModel("spot")
    }
    
    func addModel(name : String){
        
        var mesh : Mesh? = meshes[name]
        if mesh == nil {
            print("Add new mesh for \(name)")
            mesh = Mesh(name: name, renderer: self.renderer)
            meshes[name] = mesh
        }
        
        let m = Model(name: name)
        models.append(m)
        m.hitbox = mesh!.hitbox
        
        print("Added new model \(name), total nr models: \(models.count)")
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
        let translation = panner.translationInView(self.view)

        models[1].moveBy(float3(Float(translation.x) * 0.01, Float(-translation.y) * 0.01, 0))
        panner.setTranslation(CGPointZero, inView: self.view)
    }
    
    func pinched(pincher : UIPinchGestureRecognizer){
        let scale = Float(pincher.scale)
        if pincher.state == .Began {
            
        } else if pincher.state == .Changed {
            let delta = scale - lastScale
            var pos = camera.position
            pos.z += delta * 2
            camera.position = pos
        }
        
        lastScale = scale
    }
    

    func updateUniforms(model : Model){

        var uniform = camera.getUniform(model.transform)
        if model.uniformBuffer == nil {
            model.uniformBuffer = self.renderer.newBufferWithBytes(&uniform, length: sizeof(Uniforms))
        } else{
            memcpy(model.uniformBuffer!.contents(), &uniform, sizeof(Uniforms));
        }

    }
    
    func redraw(){
        
        self.renderer.startFrame()
        
        for m in models {
            updateUniforms(m)
            let mesh = meshes[m.model_key]!
            self.renderer.drawMesh(mesh, uniformBuffer: m.uniformBuffer!)
        }
        
        self.renderer.endFrame()
    }
}



