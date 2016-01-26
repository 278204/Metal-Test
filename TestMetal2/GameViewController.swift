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

class GameViewController:UIViewController, ModelDelegate, GamePadDelegate{
    
    var models      = [Model]()
    let graphics    = Graphics()
    var lastScale   = Float(0.0)
    
    var displayLink : CADisplayLink?
    let quadTree = QuadTree(level: 0, bounds: CGRect(x: 0, y: 0, width: 500, height: 500))
    
    override func viewDidLoad() {

        super.viewDidLoad()
        graphics.start((self.view.layer as? CAMetalLayer)!)
        graphics.camera.moveOffset(float3(0,0,0))
        
        GamePad.shared.delegate = self
        
        let rotater = UIPanGestureRecognizer(target: self, action: Selector("pannedTwoFingers:"))
        rotater.minimumNumberOfTouches = 1
        self.view.addGestureRecognizer(rotater)
        

        addModel("LittleBoy")
        models[0].delegate = self
        models[0].rotateX(-90)
        models[0].rotateY(-90)
        models[0].moveBy(float3(Settings.gridSize * 2, 15, 0))
//        models[0].scale(5.0)
        models[0].didUpdateHitbox()
        
        let level = Level()
        level.importLevel("test.lvl")
        print("level \(level.id) ")
        
        
        var i = 0
        for o in level.objects {
            let object_id = ObjectIDs(rawValue: o.id)
            addModel("\(object_id!)")
            models[i+1].dynamic = false
            models[i+1].collision_bit = o.collision_bit
            models[i+1].can_rest = o.can_rest
            models[i+1].moveBy(float3(Float(o.x_pos) * Settings.gridSize, Float(o.y_pos) * Settings.gridSize,0))
            i += 1
        }
       
    }
    
    func addModel(name : String){
        
        let mesh = graphics.addModel(name)
        let ro = RenderingObject(mesh_key: name)
        
        ro.skeleton = mesh.skeleton
        ro.skeletonBuffer = mesh.skeletonBuffer
        let m = Model(name: name, renderingObject: ro)
        
        m.hitbox = mesh.hitbox

        m.resetToOrigin()
        m.hitbox?.printOut()
        print("m.rect \(m.rect)")
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
            
            update(delta * Settings.gameSpeed)
        }
        
        lastTime = currentTime
        
        graphics.redraw(models)
        
        if GamePad.shared.controllerConnected {
            GamePad.shared.checkButtons()
        }
    }
    
    func panned(panner : UIPanGestureRecognizer){
        
        
    }
    
    func pannedTwoFingers(panner : UIPanGestureRecognizer){
        
        let translation = panner.translationInView(self.view)
        models[0].rotateY(Float(translation.x))
        panner.setTranslation(CGPointZero, inView: self.view)
    }
    
    
    func update(dt : Double){
//        quadTree.clear()
//        for m in models where m.can_rest == false{
//            if m.dynamic == true {
//                m.update(Float(dt))
//            }
//            
//            let rect = m.rect
//            quadTree.insert((rect, m))
//        }
        
        for m in models where m.dynamic == true && m.can_rest == false{
//            let rect = m.rect
//            let l = quadTree.retrieveList(rect)
            m.update(Float(dt))
            
            
            for obj in models where (obj !== m) && obj.can_rest == false/* && (CGRectIntersectsRect(obj.rect, rect))*/{
                m.handleIntersectWithRect(obj)
            }
            
            m.updateToNextRect()
            if m === models[0] && m.position.y < -2 {
                print("GameOver")
            }
        }
    }
    
    func modelDidChangePosition(model: Model) {
        var cam_pos = graphics.camera.position
        cam_pos.x = -max(model.position.x, 16)
        cam_pos.y = -(model.position.y + 4)
        graphics.camera.position = cam_pos
        
    }
    
    func gamePadDidPressButton(button: Button) {
        print("Did press \(button)")
        switch(button){
        case .A:
            models[0].jumpStart()
        case .Left:
            models[0].runLeft()
        case .Right:
            models[0].runRight()
        default:
            break
        }
    }
    func gamePadDidReleaseButton(button: Button) {
        print("Did release \(button)")
        switch(button){
        case .A:
            models[0].jumpEnd()
        case .Left:
            models[0].stop()
        case .Right:
            models[0].stop()
        default:
            break
        }
    }

}



