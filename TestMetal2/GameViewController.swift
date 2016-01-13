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
    
    var models      = [Model]()
    let graphics    = Graphics()
    var lastScale   = Float(0.0)
    
    var displayLink : CADisplayLink?
    let quadTree = QuadTree(level: 0, bounds: CGRect(x: -250, y: -250, width: 500, height: 500))
    
    override func viewDidLoad() {

        super.viewDidLoad()
        graphics.start((self.view.layer as? CAMetalLayer)!)
        let panner = UIPanGestureRecognizer(target: self, action: Selector("panned:"))
        panner.minimumNumberOfTouches = 1
        panner.maximumNumberOfTouches = 1
        self.view.addGestureRecognizer(panner)
        
        let rotater = UIPanGestureRecognizer(target: self, action: Selector("pannedTwoFingers:"))
        rotater.minimumNumberOfTouches = 2
        self.view.addGestureRecognizer(rotater)
        
        let pincher = UIPinchGestureRecognizer(target: self, action: Selector("pinched:"))
        self.view.addGestureRecognizer(pincher)

        let presser = UILongPressGestureRecognizer(target: self, action: Selector("tapped:"))
        presser.minimumPressDuration = 0.5
        self.view.addGestureRecognizer(presser)

        addModel("SuperDude")
        
        let floor = Model(name: "Floor")
        floor.hitbox = Box(origin:float3(-100, -100, -1), width: 200, height:99, depth: 2)
        floor.dynamic = false
        models.append(floor)
        
    }
    
    func addModel(name : String){
        
        let mesh = graphics.addModel(name)
        let m = Model(name: name)
        
//        m.dynamic = false
        m.hitbox = mesh.hitbox
        m.transform = mesh.transform!
        models.append(m)
        
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
    
    var lastTime : Double = 0
    func displayDidLinkFire(dLink : CADisplayLink){
        let currentTime = CACurrentMediaTime();
        let delta = currentTime - lastTime
        
        if lastTime > 0 {
            
            update(delta * PhysicsSettings.gameSpeed)
        }
        
        lastTime = currentTime
        
        graphics.redraw(models)
    }
    
    var skeleton_ani = 1
    func panned(panner : UIPanGestureRecognizer){
        
        let translation = panner.translationInView(self.view)
        models[0].rotateY(Float(translation.x))
        models[0].rotateX(Float(translation.y))
        panner.setTranslation(CGPointZero, inView: self.view)
        
    }
    
    func pannedTwoFingers(panner : UIPanGestureRecognizer){
        
        let translation = panner.translationInView(self.view)
        models[0].moveBy(float3(Float(translation.x), Float(translation.y), 0))
        panner.setTranslation(CGPointZero, inView: self.view)
        
    }
    
    func pinched(pincher : UIPinchGestureRecognizer){
        let scale = Float(pincher.scale)
        if pincher.state == .Began {
            
        } else if pincher.state == .Changed {
            let delta = scale - lastScale
            graphics.camera.moveZ(delta * 10)
        }
        
        lastScale = scale
    }
    
    var frame_index = 0
    func tapped(tapper : UITapGestureRecognizer){
        
        switch tapper.state{
        case .Began:
            models[0].jumpStart()
        case .Ended:
            models[0].jumpEnd()
        case .Cancelled:
            models[0].jumpEnd()
        default:
            break
        }
        let mesh = graphics.meshes[models[0].model_key]
        mesh?.skeleton.runAnimation(0.1)
        
    }
    
    func update(dt : Double){
        quadTree.clear()
        for m in models {
            
             m.update(dt)
            
            let rect = m.next_rect
            quadTree.insert((rect, m))
        }
        
        for m in models where m.dynamic == true{
            
            let rect = m.next_rect
            let l = quadTree.retrieveList(rect)
            
            let mesh = graphics.meshes[m.model_key]
            mesh?.skeleton.runAnimation(Float(dt))
            
            for obj in l where (obj.model !== m) && (CGRectIntersectsRect(obj.rect, rect)){
                m.handleIntersectWithRect(obj.rect)
            }
            
            m.updateToNextRect()
        }
    }
    


}



