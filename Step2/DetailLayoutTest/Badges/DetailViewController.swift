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
        titleLabel.text = "Probability and statistics: Random variables and probability distributions"
        descriptionLabel.text = "Achieve mastery in all skills in Probability and statistics: Random variables and probability distributions"
        imageView.image = UIImage(named: "Image-0")
    }
}
