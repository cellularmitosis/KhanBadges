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
    var dataModel: BadgeTableViewCellDataModelProtocol? {
        didSet {
            _applyDataModel(dataModel)
        }
    }

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
        dataModel = PartialDataModel.emptyModel()
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
        let id: String
        let title: String
        let image: UIImage = { UIImage(named: "question_mark.png")! }()
        
        init(id: String, title: String)
        {
            self.id = id
            self.title = title
        }
        
        init(dto: BadgeDTO)
        {
            self.id = dto.name
            self.title = dto.translated_description
        }
        
        static func emptyModel() -> PartialDataModel
        {
            return PartialDataModel(id: "", title: "")
        }
    }
    
    struct CompleteDataModel: BadgeTableViewCellDataModelProtocol
    {
        let id: String
        let title: String
        let image: UIImage
        
        init(partialModel: PartialDataModel, image: UIImage)
        {
            self.id = partialModel.id
            self.title = partialModel.title
            self.image = image
        }
    }
    
    private func _applyDataModel(model: BadgeTableViewCellDataModelProtocol?)
    {
        textLabel?.text = model?.title
        imageView?.image = model?.image
    }
}
