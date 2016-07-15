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
    
class GameViewController : UIViewController, GamePadDelegate, GameWorldDelegate{
    var metalView : MetalView {get {return self.view as! MetalView}}
    let gameWorld : GameWorld
    var level : LevelHandler?
    var displayLink : CADisplayLink?
    var pauseMenu : PauseTableView?
    var completed = false
    var lastScreenshot : UIImage?
    
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
        self.displayLink?.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode)
    }
    
    override func viewWillDisappear(animated: Bool) {
        self.displayLink?.removeFromRunLoop(NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode)
        self.displayLink?.invalidate()
        self.displayLink = nil
    }
    
    func displayDidLinkFire(dLink : CADisplayLink){
        if GamePad.shared.controllerConnected {
            GamePad.shared.checkButtons()
        }
//        if !completed {
            self.gameWorld.gameLoop()
//        }
        
    }

    
    func gamePadDidPressButton(button: Button) {
        if gameWorld.paused == false {
            switch(button){
            case .A:
                gameWorld.player.jumpStart()
            case .Left:
                gameWorld.player.runLeft()
            case .Right:
                gameWorld.player.runRight()
            case .LeftTrigger:
                gameWorld.timeModifier = 0.3
            case .RightTrigger:
                gameWorld.player.canPickUp = true
            default:
                break
            }
        }
    }
    
    func gamePadDidReleaseButton(button: Button) {
        if gameWorld.paused == false {
            switch(button){
            case .A:
                gameWorld.player.jumpEnd()
            case .Left:
                gameWorld.player.stop()
            case .Right:
                gameWorld.player.stop()
            case .LeftTrigger:
                gameWorld.timeModifier = 1.0
            case .RightTrigger:
                gameWorld.player.canPickUp = false
                gameWorld.player.releaseChildren()
            default:
                break
            }
        } else {
            switch(button){
            case .A:
                pauseMenu?.selectCurrent()
            case .Up:
                pauseMenu?.selectPrevious()
            case .Down:
                pauseMenu?.selectNext()
            default:
                break
            }
        }
    }
    
    func gamePadDidPressPause() {
        
    }
    
    
    func gameWorldWasPaused(gameWorld: GameWorld) {
    }
    
    func gameWorldWasResumed(gameWorld: GameWorld) {
    }
    
    func gameWorldWasCompleted(gameWorld: GameWorld) {
        if gameWorld.graphics.renderer.metalLayer?.framebufferOnly == false{
            if let image = gameWorld.graphics.renderer.lastDrawable!.texture.toImage() {
                self.lastScreenshot = UIImage(CGImage: image)
            } else {
                print("WARNING, couldn't capture image")
            }
        } else {
            print("WARNING, frameBuffer true")
        }
        

        self.completed = true
        self.gameWorld.paused = true
        self.gameWorld.reset()
    }
    
    func gameWorldWillRestore(gameWorld: GameWorld) {
        
    }
    

}