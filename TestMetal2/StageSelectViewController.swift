//
//  StageSelectViewController.swift
//  TestMetal2
//
//  Created by Pål Forsberg on 2016-02-15.
//  Copyright © 2016 Pål Forsberg. All rights reserved.
//

import UIKit

class StageSelectViewController: OptionsController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    
    @IBAction func eazyTapped(button : UIButton?) {
        if button != nil {
            buttonTapped(button!)
        }
    }
    
    @IBAction func normalTapped(button : UIButton?) {
        if button != nil {
            buttonTapped(button!)
        }
    }
    
    @IBAction func hardTapped(button : UIButton?) {
        if button != nil {
            buttonTapped(button!)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
