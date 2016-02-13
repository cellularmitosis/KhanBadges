//
//  ViewController.swift
//  LayoutTestA
//
//  Created by Pepas Personal on 2/13/16.
//  Copyright © 2016 Pepas Labs. All rights reserved.
//

import UIKit

// thanks mattt http://stackoverflow.com/a/24318861
func delay(delay:Double, closure:()->()) {
    dispatch_after(
        dispatch_time(
            DISPATCH_TIME_NOW,
            Int64(delay * Double(NSEC_PER_SEC))
        ),
        dispatch_get_main_queue(), closure)
}

class ViewController: UIViewController {

    @IBOutlet weak var cyanHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var magentaHeightConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        cyanHeightConstraint.cycleConstraint(minConstant: 60, maxConstant: 120)
        magentaHeightConstraint.cycleConstraint(minConstant: 120, maxConstant: 180)
    }
}

extension NSLayoutConstraint
{
    func cycleConstraint(minConstant minConstant: CGFloat, maxConstant: CGFloat, expanding: Bool = true, fps: Int = 60)
    {
        var continueExpanding = expanding
        var extraDelay = 0.0
        
        if expanding
        {
            if self.constant < maxConstant
            {
                self.constant += 1
            }
            else
            {
                continueExpanding = false
            }
        }
        else
        {
            if self.constant > minConstant
            {
                self.constant -= 1
            }
            else
            {
                continueExpanding = true
                extraDelay = 3.5
            }
        }
        
        delay(1.0/Double(fps) + extraDelay) { () -> () in
            self.cycleConstraint(minConstant: minConstant, maxConstant: maxConstant, expanding: continueExpanding, fps: fps)
        }
    }
}
