//
//  GameWorld.swift
//  TestMetal2
//
//  Created by Pål Forsberg on 2016-01-30.
//  Copyright © 2016 Pål Forsberg. All rights reserved.
//

import Foundation
import simd



class GameWorld : NSObject, ModelDelegate{
    
    var level : Level?
    var player : Player
    var models      = [Object]()
    let graphics    = Graphics.shared
    var timeModifier : Double = 1.0
    var lastTime : Double = 0
    
    let quadTree = QuadTree(level: 0, bounds: float4(0, 0, Settings.gridSize * 20, Settings.gridSize * 12))
    var finished_loading = false
    
    override init(){
        graphics.camera.moveOffset(float3(0,0,0))
        player = Player()
        super.init()
        initPlayer()
        
    }
    
    
    func playLevel(lvl : Level){

        self.level = lvl
        
        for o in lvl.objects {
            let _ = ObjectIDs(rawValue: o.id)
            let c = addBox()
            
            c.collision_bit = o.collision_bit
            c.can_rest = o.can_rest
            c.moveBy(float3(Float(o.x_pos) * Settings.gridSize, Float(o.y_pos) * Settings.gridSize,0))
            if !c.can_rest {
                quadTree.insert(c)
            }
        }
        
        let enemy = BoxEnemy()
        enemy.moveBy(float3(14 * Settings.gridSize, 3 * Settings.gridSize, 0))
        enemy.delegate = self
        models.append(enemy)
        
        let enemy2 = BoxEnemy()
        enemy2.moveBy(float3(14 * Settings.gridSize, 5 * Settings.gridSize, 0))
        enemy2.delegate = self
        models.append(enemy2)
        
        finished_loading = true
    }
    func reset(){
        guard self.level != nil else {
            print("Can't reset with nil level")
            return
        }
        models.removeAll()
        quadTree.clear()
        graphics.camera.moveOffset(float3(0,0,0))
        player = Player()
        initPlayer()
        playLevel(self.level!)
    }
    
    func initPlayer(){
        player.delegate = self
        player.moveBy(float3(Settings.gridSize * 2, 15, 2))
        models.append(player)
    }
    
    func addBox() -> Cube{
        let m = Cube()
        models.append(m)
        return m
    }
    

    func gameLoop(){
        let currentTime = CACurrentMediaTime();
        let delta = (currentTime - lastTime) * timeModifier
        
        if finished_loading == false {
            return
        }
        if lastTime > 0 {
            
            update(delta * Settings.gameSpeed)
        }
        
        lastTime = currentTime
        self.graphics.redraw(self.models)
        
        if GamePad.shared.controllerConnected {
            GamePad.shared.checkButtons()
        }
    }
    
    func update(dt : Double){
        quadTree.clearModels()
        
        for m in models {
            if Settings.showRedObjectsInQuad {
                m.renderingObject?.textureName = "Texture.png"
            }
            if m is Model {
                (m as! Model).update(Float(dt), currentTime: Float(lastTime))
                quadTree.insert(m)
            }
        }
        
        for m_o in models where m_o is Model{
            let m = m_o as! Model
//            m.update(Float(dt), currentTime: Float(lastTime))
            let quad_node_objects = quadTree.retrieveList(m)
            
            for obj in quad_node_objects where obj !== m {
                if Settings.showRedObjectsInQuad {
                    obj.renderingObject?.textureName = "Texture2.png"
                }
                m.checkIntersectWithRect(obj, dt: Float(dt))
            }
            
            m.updateToNextRect()
        }
    }
    
    func modelDidChangePosition(model: Model) {
        if model === player {
            var cam_pos = graphics.camera.position
            cam_pos.x = -max(model.position.x, 16)
            cam_pos.y = -max(model.position.y + 4, 10)
            graphics.camera.position = cam_pos
        }
    }
    
    func modelDidDie(model: Model) {
        if model === player {
            reset()
        } else {
            let i = models.indexOf { (m) -> Bool in return m === model }
            if let im = i {
                models.removeAtIndex(im)
            }
        }
    }
}