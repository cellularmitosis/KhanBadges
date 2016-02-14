//
//  DetailViewController.swift
//  Badges
//
//  Created by Pepas Personal on 2/11/16.
//  Copyright © 2016 Pepas Labs. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController
{
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        FakeAnalytics.recordEvent("DetailViewController.viewDidLoad")
    }
    
    @IBAction func dismiss(sender: AnyObject?)
    {
        self.parentViewController!.dismissViewControllerAnimated(true, completion: nil)
    }
}
