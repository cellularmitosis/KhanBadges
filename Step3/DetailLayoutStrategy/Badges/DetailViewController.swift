//
//  DetailViewController.swift
//  Badges
//
//  Created by Pepas Personal on 2/11/16.
//  Copyright © 2016 Pepas Labs. All rights reserved.
//

import UIKit

let longTitle = "Probability and statistics: Random variables and probability distributions and probability distributions and probability distributions and probability distributions and probability distributions and probability distributions and probability distributions and probability distributions and probability distributions and probability distributions and probability distributions and probability distributions and probability distributions and probability distributions and probability distributions and probability distributions and probability distributions and probability distributions"

let longDescription = "Achieve mastery in all skills in Probability and statistics: Random variables and probability distributions and probability distributions and probability distributions and probability distributions and probability distributions and probability distributions and probability distributions and probability distributions and probability distributions and probability distributions and probability distributions and probability distributions and probability distributions and probability distributions and probability distributions and probability distributions and probability distributions and probability distributions and probability distributions and probability distributions and probability distributions and probability distributions and probability distributions and probability distributions and probability distributions and probability distributions and probability distributions and probability distributions and probability distributions and probability distributions and probability distributions and probability distributions and probability distributions"

class DetailViewController: UIViewController
{
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    
    override func viewDidLoad() {
        titleLabel.text = "Probability and statistics: Random variables and probability distributions"
        descriptionLabel.text = "Achieve mastery in all skills in Probability and statistics: Random variables and probability distributions"

        titleLabel.backgroundColor = UIColor.lightGrayColor()
        descriptionLabel.backgroundColor = UIColor.lightGrayColor()
        imageView.backgroundColor = UIColor.lightGrayColor()

        imageView.image = UIImage(named: "Image-0")
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

//        titleLabel.cycleText(text: longTitle, minCharCount: 48, maxCharCount: 320, fps: 45)
        descriptionLabel.cycleText(text: longDescription, minCharCount: 240, maxCharCount: 560, fps: 75)
    }
}

// thanks mattt http://stackoverflow.com/a/24318861
func delay(delay:Double, closure:()->()) {
    dispatch_after(
        dispatch_time(
            DISPATCH_TIME_NOW,
            Int64(delay * Double(NSEC_PER_SEC))
        ),
        dispatch_get_main_queue(), closure)
}

extension UILabel
{
    func cycleText(text text: String, minCharCount: Int, maxCharCount: Int, expanding: Bool=true, fps: Int=45)
    {
        var continueExpanding = expanding
        var extraDelay = 0.0
        
        let length = self.text!.lengthOfBytesUsingEncoding(NSUTF8StringEncoding)

        if expanding
        {
            if length < maxCharCount
            {
                self.text = text.substringToIndex(text.startIndex.advancedBy(length + 1))
            }
            else
            {
                continueExpanding = false
            }
        }
        else
        {
            if length > minCharCount
            {
                self.text = text.substringToIndex(text.startIndex.advancedBy(length - 1))
            }
            else
            {
                continueExpanding = true
                extraDelay = 3.5
            }
        }
        
        delay(1.0/Double(fps) + extraDelay) { () -> () in
            self.cycleText(text: text, minCharCount: minCharCount, maxCharCount: maxCharCount, expanding: continueExpanding, fps: fps)
        }
    }
}
