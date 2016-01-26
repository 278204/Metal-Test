//
//  LevelEditorViewController.swift
//  TestMetal2
//
//  Created by Pål Forsberg on 2016-01-18.
//  Copyright © 2016 Pål Forsberg. All rights reserved.
//

import UIKit
import simd
class LevelEditorViewController: UIViewController {
    let graphics    = Graphics()
    var displayLink : CADisplayLink?
    var grid : GridMesh?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        graphics.start((self.view.layer as? CAMetalLayer)!)
        graphics.camera.moveOffset(float3(-Settings.gridSize * 4, -Settings.gridSize * 7, 0))
        grid = GridMesh(renderer: graphics.renderer)
        
        let presser = UILongPressGestureRecognizer(target: self, action: Selector("tapped:"))
        presser.minimumPressDuration = 0.0
        self.view.addGestureRecognizer(presser)
        
        let panner = UIPanGestureRecognizer(target: self, action: Selector("panned:"))
        panner.minimumNumberOfTouches = 2
        panner.maximumNumberOfTouches = 2
        self.view.addGestureRecognizer(panner)
        
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
//        let delta = currentTime - lastTime
        
        if lastTime > 0 {
            
        }
        
        lastTime = currentTime

    }
    
    func tapped(tapper : UITapGestureRecognizer){
        let location = tapper.locationInView(self.view)
        let world_coor = getWorldCoordinates(location)
        
        print("tapped \(location) \(world_coor)")
        
    }
    
    func panned(panner : UIPanGestureRecognizer){
        
        let translation = panner.translationInView(self.view)
        graphics.camera.moveOffset(float3(Float(translation.x * 0.1), Float(-translation.y * 0.1), 0))
        print("camera pos: \(graphics.camera.position)")
        panner.setTranslation(CGPointZero, inView: self.view)
        
    }

    
    func getWorldCoordinates(pos : CGPoint) -> float4{
 
        let x = 2 * pos.x / self.view.frame.size.width - 1
        let y = -2 * pos.y / self.view.frame.size.height + 1
        
        let inv_view_proj = (graphics.camera.projection_matrix * graphics.camera.view_matrix).inverse
        let pos3d = float4(Float(x), Float(y), -1, 1)
        var res = inv_view_proj * pos3d
        res.x /= res.w
        res.y /= res.w
        return res
    }
    
    
}
