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

class GameViewController : UIViewController, GamePadDelegate{
    var metalView : MetalView {get {return self.view as! MetalView}}
    let gameWorld : GameWorld
    var level : Level?
    var displayLink : CADisplayLink?
    
    
    required init?(coder aDecoder: NSCoder) {
        gameWorld = GameWorld()
        super.init(coder: aDecoder)
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        gameWorld.graphics.start(self.view.layer as! CAMetalLayer)
        GamePad.shared.delegate = self
        
        if level == nil {
            level = Level()
            level!.importLevel("test.lvl")
        }
        gameWorld.playLevel(level!)
        
        #if TARGET_OS_IOS
        let rotater = UIPanGestureRecognizer(target: self, action: Selector("pannedTwoFingers:"))
        rotater.minimumNumberOfTouches = 1
        self.view.addGestureRecognizer(rotater)
        #endif
        
//        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 100, height: 40))
//        label.text = level!.name
//        self.metalView.addSubview(label)
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    override func viewDidAppear(animated: Bool){
        self.displayLink = UIScreen.mainScreen().displayLinkWithTarget(self, selector: "displayDidLinkFire:")
//        self.displayLink = CADisplayLink(target: self, selector: "displayDidLinkFire:")
        self.displayLink?.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode)
    }
    
    override func viewWillDisappear(animated: Bool) {
        self.displayLink?.invalidate()
        self.displayLink = nil
    }
    
    func displayDidLinkFire(dLink : CADisplayLink){
        self.gameWorld.gameLoop()
    }
    
    func pannedTwoFingers(panner : UIPanGestureRecognizer){
        let translation = panner.translationInView(self.view)
        gameWorld.player.rotateY(Float(translation.x))
        panner.setTranslation(CGPointZero, inView: self.view)
    }
    
    func gamePadDidPressButton(button: Button) {
//        print("Did press \(button)")
        switch(button){
        case .A:
            gameWorld.player.jumpStart()
        case .Left:
            gameWorld.player.runLeft()
        case .Right:
            gameWorld.player.runRight()
        case .LeftTrigger:
            gameWorld.timeModifier = 0.3
        default:
            break
        }
    }
    
    func gamePadDidReleaseButton(button: Button) {
        switch(button){
        case .A:
            gameWorld.player.jumpEnd()
        case .Left:
            gameWorld.player.stop()
        case .Right:
            gameWorld.player.stop()
        case .LeftTrigger:
            gameWorld.timeModifier = 1.0
        default:
            break
        }
    }

}



