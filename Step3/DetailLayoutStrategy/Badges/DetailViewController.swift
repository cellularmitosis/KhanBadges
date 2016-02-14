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
    
    @IBOutlet weak var imageViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageViewVerticallyCenteredConstraint: NSLayoutConstraint!

    @IBOutlet weak var titleToImageVerticalSpacingConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageToDescriptionVerticalSpacingConstraint: NSLayoutConstraint!
    
    @IBOutlet var verticalPaddingConstraints: [NSLayoutConstraint]!
    @IBOutlet var horizontalPaddingConstraints: [NSLayoutConstraint]!
    @IBOutlet var verticalGutterConstraints: [NSLayoutConstraint]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        titleLabel.text = "Probability and statistics: Random variables and probability distributions"
        descriptionLabel.text = "Achieve mastery in all skills in Probability and statistics: Random variables and probability distributions"

//        titleLabel.backgroundColor = UIColor.lightGrayColor()
//        descriptionLabel.backgroundColor = UIColor.lightGrayColor()
//        imageView.backgroundColor = UIColor.lightGrayColor()

        imageView.image = UIImage(named: "Image-0")
        
        applyStyleModel(styleModel)
        applyLayoutModel(layoutModel)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        titleLabel.cycleText(text: longTitle, minCharCount: 48, maxCharCount: 320, fps: 45)
//        descriptionLabel.cycleText(text: longDescription, minCharCount: 240, maxCharCount: 560, fps: 75)
    }
    
    var layoutModel: LayoutModel = LayoutModel.defaultModel() {
        didSet {
            applyLayoutModelIfViewLoaded(layoutModel)
        }
    }
    
    var styleModel: StyleModel = StyleModel.defaultModel() {
        didSet {
            applyStyleModelIfViewLoaded(styleModel)
        }
    }
}

func deviceWidth() -> CGFloat
{
    // Note: this will return e.g. 320 regardless of what orientation the phone is currently held.
    return UIScreen.mainScreen().bounds.size.width
}

extension CGFloat
{
    func scaled(factor: CGFloat) -> CGFloat
    {
        return round(self * factor)
    }
}

extension DetailViewController
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
            let factor = deviceWidth() / designedForWidth
            return self.scaled(factor)
        }
        
        private let designedForWidth: CGFloat = 375.0
    }
    
    func applyLayoutModelIfViewLoaded(model: LayoutModel)
    {
        if self.isViewLoaded()
        {
            applyLayoutModel(model)
        }
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
        
        self.view.layoutIfNeeded()
        
        debugPrint(model)
    }
}

extension UIFont
{
    func scaled(factor: CGFloat) -> UIFont
    {
        let newPointSize = pointSize * factor
        return fontWithSize(newPointSize)
    }
}

extension DetailViewController
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
            let factor = deviceWidth() / designedForWidth
            return self.scaled(factor)
        }
        
        private let designedForWidth: CGFloat = 375.0
    }
    
    func applyStyleModelIfViewLoaded(model: StyleModel)
    {
        if isViewLoaded()
        {
            applyStyleModel(model)
        }
    }
    
    func applyStyleModel(model: StyleModel)
    {
        titleLabel.font = model.titleFont
        descriptionLabel.font = model.descriptionFont
        self.view.layoutIfNeeded()
        
        debugPrint(model)
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
