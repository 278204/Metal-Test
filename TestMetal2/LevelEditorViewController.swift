//
//  LevelEditorViewController.swift
//  TestMetal2
//
//  Created by Pål Forsberg on 2016-01-18.
//  Copyright © 2016 Pål Forsberg. All rights reserved.
//

import UIKit
import simd
import CloudKit

class LevelEditorViewController: GameViewController, UITableViewDelegate, UITextFieldDelegate, UIGestureRecognizerDelegate, UIViewControllerTransitioningDelegate {
    
    @IBOutlet var sideView : UIView?
    @IBOutlet var tableView : ObjectTableView?
    @IBOutlet var nameTextField : UITextField?
    
    let graphics    = Graphics.shared
    
    var currentObjectID = ObjectIDs.Cube
    var grid = [[Int?]](count: Settings.maxGridPoint.x, repeatedValue: [Int?](count: Settings.maxGridPoint.y, repeatedValue: nil))
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
        nameTextField?.delegate = self
        tableView?.delegate = self

        self.graphics.camera.moveOffset(float3(-self.graphics.camera.frustumSize.x / 2, -self.graphics.camera.frustumSize.y / 2, 0))
        
        if self.level == nil {
            self.level = LevelHandler()
            self.gameWorld.level = self.level
            self.level!.data = LevelData()
            self.level!.data!.delegate = self.gameWorld
            self.nameTextField?.becomeFirstResponder()
        } else {
            self.gameWorld.level = self.level
            self.level!.importLevel(self.level!.id)
            self.level!.data!.delegate = self.gameWorld
            self.level!.data!.restore()
            var i = 0
            for o in self.level!.data!.objects {
                grid[o.gridPos.x][o.gridPos.y] = i
                i += 1
            }
        }
        self.nameTextField?.text = self.level!.name
        self.gameWorld.paused = true
        gameWorld.delegate = self
        
        let player = self.level?.data?.getPlayerObject()
        if player != nil {
            self.gameWorld.player = player!
            self.graphics.camera.position = -(self.gameWorld.player.rect.mid).xyz
        }
        let gridObject  = GridObject()
        self.gameWorld.helperObjects.append(gridObject)

        
        let presser = UITapGestureRecognizer(target: self, action: Selector("tapped:"))
        presser.delegate = self
        self.metalView.addGestureRecognizer(presser)
        
        let panner = UIPanGestureRecognizer(target: self, action: Selector("panned:"))
        panner.delegate = self
        self.metalView.addGestureRecognizer(panner)
            
    }

    func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        let location = gestureRecognizer.locationInView(gestureRecognizer.view)
        for s in self.sideView!.subviews {
            if CGRectContainsPoint(s.frame, location) {
                return false
            }
        }
        return true
    }
    
    func tapped(tapper : UITapGestureRecognizer){
        let location = tapper.locationInView(self.view)

        let world_coor = getWorldCoordinates(location)
        
        let grid_pos_x = Int(world_coor.x / Settings.gridSize)
        let grid_pos_y = Int(world_coor.y / Settings.gridSize)
        
        if grid[grid_pos_x][grid_pos_y] == nil{
            addBlockInGrid(GridPoint(x:grid_pos_x, y:grid_pos_y))
        } else {
            removeBlock(GridPoint(x:grid_pos_x, y:grid_pos_y))
        }
        level?.lastModified = NSDate()
    }
    
    func addBlockInGrid(point : GridPoint){
        print("Add \(currentObjectID) to \(point)")
        let index = level!.data!.objects.count
        let object = LevelData.objectForID(currentObjectID)
        object.gridPos = point
        object.moveBy(float3(Settings.gridSize * Float(point.x) + object.rect.width/2, Settings.gridSize * Float(point.y) + object.rect.height/2, 0))
        
        level!.data!.addObject(object, point: point)
        
        if let p = object as? Player {
            gameWorld.player = p
        }
        
        grid[point.x][point.y] = index
    }
    
    func removeBlock(point : GridPoint) {
        let index = grid[point.x][point.y]
        if index != nil {
            let o = level!.data!.objects[index!]
            level!.data!.removeObject(o)
            for i in 0..<grid.count {
                for j in 0..<grid[i].count {
                    if grid[i][j] != nil && grid[i][j] > index {
                        grid[i][j] = grid[i][j]! - 1
                    }
                }
            }
            grid[point.x][point.y] = nil
        }
    }
    
    func panned(panner : UIPanGestureRecognizer) {
        
        let translation = panner.translationInView(self.view)
        let map_x = graphics.camera.frustumSize.x / Float(self.view.bounds.size.width)
        graphics.camera.moveOffset(float3(Float(translation.x) * map_x, Float(-translation.y) * map_x, 0))
//        graphics.camera.position.x = max(-(gridObject.rect.width - graphics.camera.frustumSize.x / 2),min(-graphics.camera.frustumSize.x / 2, graphics.camera.position.x))
//        graphics.camera.position.y = max(-(gridObject.rect.height - graphics.camera.frustumSize.y / 2),min(-graphics.camera.frustumSize.y / 2, graphics.camera.position.y))
        panner.setTranslation(CGPointZero, inView: self.view)
    }

    
    func getWorldCoordinates(pos : CGPoint) -> float4{
 
        let x = 2 * pos.x / self.metalView.frame.size.width - 1
        let y = -2 * pos.y / self.metalView.frame.size.height + 1
        
        let inv_view_proj = (graphics.camera.projection_matrix * graphics.camera.view_matrix).inverse
        let pos3d = float4(Float(x), Float(y), -1, 1)
        var res = inv_view_proj * pos3d
        res.x /= res.w
        res.y /= res.w
        return res
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        currentObjectID = self.tableView!.content[indexPath.row]
    }

    func startEditing(){
        print("START editing")
        self.level?.data?.restore()
        
        sideView?.hidden = false
//        self.gameWorld.paused = true
    }
    
    func stopEditing(){
        if level?.data!.getPlayerObject() == nil {
            let alert = UIAlertController(title: "No player", message: "You must add a player", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Cancel, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
            return
        }
        level?.data!.updateLevelObjects()
        sideView?.hidden = true
//        self.gameWorld.paused = false
    }
    
    func saveLevelUserDefaults(){
        let data = NSKeyedArchiver.archivedDataWithRootObject(level!)
        var array = NSUserDefaults.standardUserDefaults().valueForKey("UnfinishedLevels") as? [NSData]
        if array == nil {
            array = [NSData]()
        }
        var conv_arr = [LevelHandler]()
        for d in array!{
            let lh = NSKeyedUnarchiver.unarchiveObjectWithData(d) as! LevelHandler
            conv_arr.append(lh)
        }
        let index = conv_arr.indexOf { (lh) -> Bool in
            return lh.id == self.level!.id
        }
        if index == nil {
            array!.append(data)
        } else {
            array!.removeAtIndex(index!)
            array!.insert(data, atIndex: index!)
        }
        
        NSUserDefaults.standardUserDefaults().setValue(array, forKey: "UnfinishedLevels")
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    @IBAction func playButtonTapped(button : UIButton){
        stopEditing()
    }
    
    @IBAction func saveButtonTapped(button : UIButton){
        level!.export()
        self.saveLevelUserDefaults()
        button.setTitle("Saved", forState: .Normal)
    }
    @IBAction func exitButtonTapped(button : UIButton){
        let tc = self.storyboard?.instantiateViewControllerWithIdentifier("Tab")
        self.presentViewController(tc!, animated: false, completion: nil)
    }
    
    override func gamePadDidPressPause() {
        self.gameWorld.paused = !self.gameWorld.paused

    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        self.level?.name = textField.text!
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    override func gameWorldWasPaused(gameWorld: GameWorld) {
        if !completed {
            startEditing()
        }
    }
    
    override func gameWorldWasResumed(gameWorld: GameWorld) {
        if !completed {
            stopEditing()
        }
    }
    
    override func gameWorldWasCompleted(gameWorld: GameWorld) {
        super.gameWorldWasCompleted(gameWorld)
        let imageView = UIImageView(frame: self.view.bounds)
        imageView.image = self.lastScreenshot
        self.view = imageView
        
        let efvc = self.storyboard?.instantiateViewControllerWithIdentifier("EditLevelFinished") as! EditLevelFinishedViewController

        efvc.level = self.level
//        efvc.transitioningDelegate = self
//        efvc.modalPresentationStyle = UIModalPresentationStyle.Custom
        
        self.presentViewController(efvc, animated: false, completion: nil)
        
    }
    
    override func gameWorldWillRestore(gameWorld: GameWorld) {
        
    }
    
    func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return VCTransition()
    }
    
}

class VCTransition : NSObject, UIViewControllerAnimatedTransitioning {
    
    
    func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
        return 2.0
    }
    
    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        let fromVC = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey)!
        let toVC = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey)!
        
        let container = transitionContext.containerView()!
        container.addSubview(fromVC.view)
        container.addSubview(toVC.view)
        
        toVC.view.frame.origin.x += container.frame.size.width
        
        UIView.animateWithDuration(self.transitionDuration(transitionContext), animations: { () -> Void in
            container.frame.origin.x = -container.frame.size.width

            }) { (completed) -> Void in
                transitionContext.completeTransition(true)
        }
    }
}
