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
    
    override func prepareForReuse()
    {
        let model = PartialDataModel.emptyModel()
        applyDataModel(model)
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
        
        init(dto: BadgeDTO)
        {
            self.title = dto.translated_description
        }
        
        static func emptyModel() -> PartialDataModel
        {
            return PartialDataModel(title: "")
        }
    }
    
    struct CompleteDataModel: BadgeTableViewCellDataModelProtocol
    {
        let title: String
        let image: UIImage
        
        init(partialModel: PartialDataModel, image: UIImage)
        {
            self.title = partialModel.title
            self.image = image
        }
    }
    
    func applyDataModel(model: BadgeTableViewCellDataModelProtocol)
    {
        textLabel?.text = model.title
        imageView?.image = model.image
    }
}
