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
    
    @IBOutlet weak var imageViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageViewVerticallyCenteredConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var titleToImageVerticalSpacingConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageToDescriptionVerticalSpacingConstraint: NSLayoutConstraint!
    
    @IBOutlet var verticalPaddingConstraints: [NSLayoutConstraint]!
    @IBOutlet var horizontalPaddingConstraints: [NSLayoutConstraint]!
    @IBOutlet var verticalGutterConstraints: [NSLayoutConstraint]!
    
    var dataModel: DataModel = DataModel.defaultModel() {
        didSet {
            applyDataModelIfViewLoaded(dataModel)
        }
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

    var dataService: DataModelService? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        applyDataModel(dataModel)
        applyStyleModel(styleModel)
        applyLayoutModel(layoutModel)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        dataService?.subscribe { (model) -> () in
            self.dataModel = model
        }
    }

    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        dataService?.unsubscribe()
    }
    
    @IBAction func dismiss(sender: AnyObject?)
    {
        self.parentViewController!.dismissViewControllerAnimated(true, completion: nil)
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
    
    func applyDataModelIfViewLoaded(model: DataModel)
    {
        if isViewLoaded()
        {
            applyDataModel(model)
        }
    }
    
    func applyDataModel(model: DataModel)
    {
        titleLabel.text = model.title
        descriptionLabel.text = model.description
        imageView.image = model.image
        
        self.view.layoutIfNeeded()
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
        
//        debugPrint(model)
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
        
//        debugPrint(model)
    }
}

extension DetailViewController
{
    typealias DataModelClosure = (DataModel)->()
    
    class DataModelService
    {
        init(title: String, description: String, imageUrlString: String, imageService: ImageService)
        {
            self.title = title
            self.description = description
            self.image = DataModel.defaultModel().image
            self.imageUrlString = imageUrlString
            self.imageService = imageService
            
            if let cachedImage = imageService.cachedImage(urlString: imageUrlString)
            {
                self.image = cachedImage
            }
            else
            {
                imageService.fetch(urlString: imageUrlString, completion: { [weak self] (result) -> () in
                    guard let weakSelf = self else { return }
                    
                    if case .Success(let fetchedImage) = result
                    {
                        weakSelf.image = fetchedImage
                        weakSelf.closure?(weakSelf.latestModel)
                    }
                })
            }
        }
        
        func subscribe(dataDidBecomeAvailableClosure: DataModelClosure)
        {
            closure = dataDidBecomeAvailableClosure
            closure?(latestModel)
        }
        
        func unsubscribe()
        {
            closure = nil
        }
        
        private var closure: DataModelClosure?
        
        private var title: String
        private var description: String
        
        private var image: UIImage
        private let imageUrlString: String
        private let imageService: ImageService
        
        private var latestModel: DataModel {
            get {
                return DataModel(
                    title: title,
                    description: description,
                    image: image
                )
            }
        }

    }
}
