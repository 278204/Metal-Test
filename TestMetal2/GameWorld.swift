//
//  GameWorld.swift
//  TestMetal2
//
//  Created by Pål Forsberg on 2016-01-30.
//  Copyright © 2016 Pål Forsberg. All rights reserved.
//

import Foundation
import simd


protocol GameWorldDelegate{
    func gameWorldWasCompleted(gameWorld : GameWorld)
    func gameWorldWasPaused(gameWorld : GameWorld)
    func gameWorldWasResumed(gameWorld : GameWorld)
    func gameWorldWillRestore(gameWorld : GameWorld)
}
class GameWorld : NSObject, ModelDelegate, LevelDataDelegate{
    
    var delegate : GameWorldDelegate?
    var paused = false {didSet{pausedDidSet()}}
    var level : LevelHandler?
    var player : Player {didSet { self.player.delegate = self}}
    let graphics    = Graphics.shared
    var timeModifier : Double = 1.0
    var lastTime : Double = 0
    let quadTree = QuadTree(level: 0, bounds: float4(0, 0, Settings.gridSize * Float(Settings.maxGridPoint.x), Settings.gridSize * Float(Settings.maxGridPoint.y)))
    var finished_loading = true
    
    var helperObjects = [Object]()
    
    override init(){
        graphics.camera.moveOffset(float3(0,0,0))
        player = Player()
        super.init()
//        initPlayer()
    }

    
    func completed(){
        self.delegate?.gameWorldWasCompleted(self)
    }
    
    func reset(){
        level!.data!.reset()
        quadTree.clear()
    }
    func restore(){
    
        guard self.level != nil else {
            print("Can't reset with nil level")
            return
        }
        paused = true
        self.delegate?.gameWorldWillRestore(self)
        level!.data!.restore()
        quadTree.clear()
        paused = false
    }
    
    func levelDataDidRestore(ld: LevelData) {
        player = level!.data!.getPlayerObject()!
    }
    
    func pausedDidSet(){
        lastTime = 0
        if paused {
            self.delegate?.gameWorldWasPaused(self)
        } else {
            self.delegate?.gameWorldWasResumed(self)
        }
    }
    
//    func initPlayer(){
//        player.delegate = self
//        player.moveBy(float3(Settings.gridSize * 2, 15, 2))
//        models.append(player)
//        objects.append(player)
//    }
    
//    func addBox() -> Cube{
//        let m = Cube()
////        models.append(m)
//        objects.append(m)
//        return m
//    }
    

    func gameLoop(){
        let currentTime = CACurrentMediaTime();
        var delta = (currentTime - lastTime) * timeModifier
        if lastTime == 0 {
            delta = 0
        }
        if finished_loading == true && paused == false {
            update(delta * Settings.gameSpeed)
        }
       
        lastTime = currentTime
        self.graphics.startFrame()
        self.graphics.redraw(self.level!.data!.objects)
        if self.paused {
            self.graphics.redraw(self.helperObjects)
        }
        self.graphics.endFrame()
    }
    
    func update(dt : Double){
        quadTree.clear()

        //WARNING, moving platforms must be updated before objects on them
        
        for skelHand in SkeletonMap.map.values {
            skelHand.reset()
        }
        
        for m in level!.data!.dynamics {
            
            m.update(Float(dt), currentTime: Float(lastTime))
            if !m.can_rest {
                quadTree.insert(m)
            }
            if m is Player{
                if m.rect.x > Float(level!.data!.max_x+1) * Settings.gridSize {
                    print("Finished level mofos")
                    completed()
                }
            }
        }
        
        for m_o in level!.data!.dynamics{
//            if m_o.dynamic {
    //            m_o.update(Float(dt), currentTime: Float(lastTime))
                if !m_o.can_rest && m_o is Model {
                    let m = m_o as! Model
                    
                    let x_pos = Int(m.rect.mid.x / Settings.gridSize) - 1
                    let y_pos = Int(m.rect.mid.y / Settings.gridSize) - 1
                    
                    for i in 0..<3 {
                        for j in 0..<3 {
                            if LevelData.insideGrid(GridPoint(x:x_pos + i, y:y_pos + j), grid: level!.data!.grid){
                                let obj = level!.data!.grid[x_pos + i][y_pos + j]
                                if obj != nil {
                                    if m.collision_bitmask & obj!.collision_type != 0  && obj!.collision_bitmask & m.collision_type != 0{
                                        m.checkIntersectWithRect(obj!, dt: Float(dt))
                                    }
                                }
                            }
                        }
                    }
                    
                    
                    var map = [Int : Bool]()
                    let quad_node_objects = quadTree.retrieveList(m.rect)
                    
                    for obj in quad_node_objects where obj !== m && map[obj.id] != true {
//                        if Settings.showRedObjectsInQuad {
//                            obj.renderingObject?.textureName = "Texture2.png"
//                        }
                        if m.collision_bitmask & obj.collision_type != 0 && obj.collision_bitmask & m.collision_type != 0 {
                            m.checkIntersectWithRect(obj, dt: Float(dt))
                        }
                        map[obj.id] = true

                    }

//                }
                
                m_o.updateToNextRect()
            }
        }
    }
    
    func modelDidChangePosition(model: Model) {
        if model === player {
            var cam_pos = graphics.camera.position
            let width_div2 = graphics.camera.frustumSize.x / 2
            let max_x = (Float(level!.data!.max_x+1) * Settings.gridSize) - width_div2
            cam_pos.x = -max(min(model.rect.x, max_x), width_div2)
            cam_pos.y = -max(model.rect.y + 4, 10)
            graphics.camera.position = cam_pos
        }
    }
    
    
    func modelWillDie(model: Model) {
        if model === player {
            if !player.dead {
                self.performSelector("restore", withObject: nil, afterDelay: 1.0)
            } else {
                print("Player already dead")
            }
        } else {
            let dispatchTime: dispatch_time_t = dispatch_time(DISPATCH_TIME_NOW, Int64(1.0 * Double(NSEC_PER_SEC)))
            dispatch_after(dispatchTime, dispatch_get_main_queue(), {
                // your function here
                self.level?.data?.removeObject(model)
            })
        }
    }
}



//
//    func playLevel(lvl : LevelHandler){
//        finished_loading = false
//        if level!.grid.count == 0 {
//            level!.grid = [[Object?]](count: 50, repeatedValue: [Object?](count: 20, repeatedValue: nil))
//        }
//        self.level = lvl
//        var i = 0
//        for o in lvl.lvlObjects {
//            let _ = o.id
//            let c = Level.objectForID(o.id)
//            if c is Player {
//                player = c as! Player
//                player.delegate = self
//            }
//            c.id = i
//            i += 1
//            c.collision_side_bit = o.collision_side_bit
//            c.can_rest = o.can_rest
//            c.moveBy(float3(Float(o.x_pos) * Settings.gridSize, Float(o.y_pos) * Settings.gridSize,-1))
//            if c.dynamic {
//                quadTree.insert(c)
//            }
//            level!.grid[Int(o.x_pos)][Int(o.y_pos)] = c
//        }
//
////        let moving = MovingPlatform()
////        moving.id = i
////        moving.moveBy(float3(15 * Settings.gridSize, 1 * Settings.gridSize, 2))
////        models.insert(moving, atIndex: 0)
////        objects.append(moving)
////        i += 1
////
////        for j in 0..<10 {
////            let enemy2 = Ghost()
////            enemy2.id = i
////            enemy2.moveBy(float3(16 + (Float(j*2) * Settings.gridSize), 6 * Settings.gridSize, 0))
////            enemy2.delegate = self
////            models.append(enemy2)
////            objects.append(enemy2)
////            i += 1
////        }
////
////        for j in 0..<10 {
////            let enemy2 = Ghost()
////            enemy2.id = i
////            enemy2.moveBy(float3(16 + (Float(j*2) * Settings.gridSize), 8 * Settings.gridSize, 0))
////            enemy2.delegate = self
////            models.append(enemy2)
////            objects.append(enemy2)
////            i += 1
////        }
////
////
////        let pickup = Shell()
////        pickup.id = i
////        pickup.moveBy(float3(4 * Settings.gridSize, 12 * Settings.gridSize, 0))
////        pickup.delegate = self
////        models.append(pickup)
////        objects.append(pickup)
////
////        i += 1
////        player.id = i
//
//        finished_loading = true
//    }