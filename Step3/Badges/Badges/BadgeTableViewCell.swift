//
//  BadgeTableViewCell.swift
//  Badges
//
//  Created by Pepas Personal on 2/15/16.
//  Copyright © 2016 Pepas Labs. All rights reserved.
//

import UIKit

class BadgeTableViewCell: UITableViewCell
{
    static var reuseIdentifier: String {
        get {
            return "\(self)"
        }
    }
    
    override var reuseIdentifier: String? {
        get {
            return BadgeTableViewCell.reuseIdentifier
        }
    }
}

protocol BadgeTableViewCellDataModelProtocol
{
    var title: String { get }
    var image: UIImage { get }
}

extension BadgeTableViewCell
{
    struct PartialDataModel: BadgeTableViewCellDataModelProtocol
    {
        let title: String
        let image: UIImage = { UIImage(named: "question_mark.png")! }()
        
        init(title: String)
        {
            self.title = title
        }
    }
    
    struct CompleteDataModel
    {
        let title: String
        let image: UIImage
    }
    
    func applyDataModel(model: BadgeTableViewCellDataModelProtocol)
    {
        textLabel?.text = model.title
        imageView?.image = model.image
    }
}
