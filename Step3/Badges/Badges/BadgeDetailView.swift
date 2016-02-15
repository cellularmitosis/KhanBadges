//
//  BadgeDetailView.swift
//  Badges
//
//  Created by Pepas Personal on 2/14/16.
//  Copyright © 2016 Pepas Labs. All rights reserved.
//

import UIKit

class BadgeDetailView: UIView
{
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var imageViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageViewVerticallyCenteredConstraint: NSLayoutConstraint!
    
    @IBOutlet var verticalPaddingConstraints: [NSLayoutConstraint]!
    @IBOutlet var horizontalPaddingConstraints: [NSLayoutConstraint]!
    @IBOutlet var verticalGutterConstraints: [NSLayoutConstraint]!
}

extension BadgeDetailView
{
    struct DataModel
    {
        let title: String
        let description: String
        let image: UIImage
        
        static func defaultModel() -> DataModel
        {
            return DataModel(
                title: "",
                description: "",
                image: UIImage(named: "question_mark.png")!
            )
        }
    }
    
    func applyDataModel(model: DataModel)
    {
        titleLabel.text = model.title
        descriptionLabel.text = model.description
        imageView.image = model.image
    }
}

extension BadgeDetailView
{
    struct LayoutModel
    {
        let imageViewWidthConstraintConstant: CGFloat
        let imageViewHeightConstraintConstant: CGFloat
        
        let verticalPadding: CGFloat
        let verticalGutter: CGFloat
        let horizontalPadding: CGFloat
        
        let imageViewVerticallyCenteredOffset: CGFloat
        
        static func defaultModel() -> LayoutModel
        {
            let model = LayoutModel(
                imageViewWidthConstraintConstant: 232,
                imageViewHeightConstraintConstant: 232,
                verticalPadding: 16,
                verticalGutter: 16,
                horizontalPadding: 16,
                imageViewVerticallyCenteredOffset: -16
            )
            return model.scaledForCurrentDevice()
        }
        
        func scaled(factor: CGFloat) -> LayoutModel
        {
            return LayoutModel(
                imageViewWidthConstraintConstant: self.imageViewWidthConstraintConstant.scaled(factor),
                imageViewHeightConstraintConstant: self.imageViewHeightConstraintConstant.scaled(factor),
                verticalPadding: self.verticalPadding.scaled(factor),
                verticalGutter: self.verticalGutter.scaled(factor),
                horizontalPadding: self.horizontalPadding.scaled(factor),
                imageViewVerticallyCenteredOffset: self.imageViewVerticallyCenteredOffset.scaled(factor)
            )
        }
        
        func scaledForCurrentDevice() -> LayoutModel
        {
            let factor = UIScreen.width() / designedForWidth
            return self.scaled(factor)
        }
        
        private let designedForWidth: CGFloat = 375.0
    }
    
    func applyLayoutModel(model: LayoutModel)
    {
        imageViewHeightConstraint.constant = model.imageViewHeightConstraintConstant
        imageViewWidthConstraint.constant = model.imageViewWidthConstraintConstant
        imageViewVerticallyCenteredConstraint.constant = model.imageViewVerticallyCenteredOffset
        
        for constraint in verticalPaddingConstraints
        {
            constraint.constant = model.verticalPadding
        }
        
        for constraint in verticalGutterConstraints
        {
            constraint.constant = model.verticalGutter
        }
        
        for constraint in horizontalPaddingConstraints
        {
            constraint.constant = model.horizontalPadding
        }
    }
}

extension BadgeDetailView
{
    struct StyleModel
    {
        let titleFont: UIFont
        let descriptionFont: UIFont
        
        static func defaultModel() -> StyleModel
        {
            let model = StyleModel(
                titleFont: UIFont.preferredFontForTextStyle(UIFontTextStyleTitle2),
                descriptionFont: UIFont.preferredFontForTextStyle(UIFontTextStyleBody)
            )
            return model.scaledForCurrentDevice()
        }
        
        func scaled(factor: CGFloat) -> StyleModel
        {
            return StyleModel(
                titleFont: self.titleFont.scaled(factor),
                descriptionFont: self.descriptionFont.scaled(factor)
            )
        }
        
        func scaledForCurrentDevice() -> StyleModel
        {
            let factor = UIScreen.width() / designedForWidth
            return self.scaled(factor)
        }
        
        private let designedForWidth: CGFloat = 375.0
    }
    
    func applyStyleModel(model: StyleModel)
    {
        titleLabel.font = model.titleFont
        descriptionLabel.font = model.descriptionFont
    }
}
