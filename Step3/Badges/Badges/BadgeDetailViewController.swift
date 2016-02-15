//
//  BadgeDetailViewController.swift
//  Badges
//
//  Created by Pepas Personal on 2/11/16.
//  Copyright © 2016 Pepas Labs. All rights reserved.
//

import UIKit

class BadgeDetailViewController: UIViewController
{
    var badgeView: BadgeDetailView {
        get {
            return view as! BadgeDetailView
        }
    }
    
    var dataModel: BadgeDetailView.DataModel = BadgeDetailView.DataModel.defaultModel() {
        didSet {
            _applyDataModelIfViewLoaded(dataModel)
        }
    }
    
    var layoutModel: BadgeDetailView.LayoutModel = BadgeDetailView.LayoutModel.defaultModel() {
        didSet {
            _applyLayoutModelIfViewLoaded(layoutModel)
        }
    }
    
    var styleModel: BadgeDetailView.StyleModel = BadgeDetailView.StyleModel.defaultModel() {
        didSet {
            _applyStyleModelIfViewLoaded(styleModel)
        }
    }

    var dataService: DataModelService? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        FakeAnalytics.recordEvent("DetailViewController.viewDidLoad")
        
        badgeView.applyDataModel(dataModel)
        badgeView.applyStyleModel(styleModel)
        badgeView.applyLayoutModel(layoutModel)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        dataService?.subscribeImmediate { [weak self] (model) -> () in
            guard let weakSelf = self else { return }
            
            weakSelf.dataModel = model
        }
    }

    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        dataService?.unsubscribe()
    }
    
    deinit
    {
        debugPrint("BadgeDetailViewController.deinit()")
    }
    
    @IBAction func dismiss(sender: AnyObject?)
    {
        self.parentViewController!.dismissViewControllerAnimated(true, completion: nil)
    }
    
    class func instantiateInNavigationControllerFromStoryboard() -> UINavigationController
    {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let navC = storyboard.instantiateViewControllerWithIdentifier("BadgeDetailViewControllerNavigationController") as! UINavigationController
        return navC
    }
}

// MARK: private methods
extension BadgeDetailViewController
{
    private func _applyDataModelIfViewLoaded(model: BadgeDetailView.DataModel)
    {
        if isViewLoaded()
        {
            badgeView.applyDataModel(model)
        }
    }
    
    private func _applyLayoutModelIfViewLoaded(model: BadgeDetailView.LayoutModel)
    {
        if self.isViewLoaded()
        {
            badgeView.applyLayoutModel(model)
        }
    }
    
    private func _applyStyleModelIfViewLoaded(model: BadgeDetailView.StyleModel)
    {
        if isViewLoaded()
        {
            badgeView.applyStyleModel(model)
        }
    }
}

// Note: pulling this out into its own file causes the Swift compiler to segfault.
extension BadgeDetailViewController
{
    typealias DataModelClosure = (BadgeDetailView.DataModel)->()
    
    class DataModelService
    {
        init(title: String, description: String, imageService: ImageService)
        {
            self.title = title
            self.description = description
            self.imageService = imageService
            self.image = BadgeDetailView.DataModel.defaultModel().image
        }
        
        func subscribeImmediate(dataDidBecomeAvailableClosure: DataModelClosure)
        {
            closure = dataDidBecomeAvailableClosure
            
            if imageService.cachedValue == nil
            {
                // If imageService doesn't have a cached value, then imageService.subscribeImmediate()
                // might take a while to return something.
                // In the mean time, call the closure immediately with the default (placeholder) image.
                closure?(latestModel)
            }
            
            imageService.subscribeImmediate(subscriber: self) { [weak self] (result) -> () in
                guard let weakSelf = self else { return }
                
                if case .Success(let image) = result
                {
                    weakSelf.image = image
                }
                
                weakSelf.closure?(weakSelf.latestModel)
            }
        }
        
        func unsubscribe()
        {
            imageService.unsubscribe(subscriber: self)
            closure = nil
        }
        
        private var closure: DataModelClosure?
        
        private var title: String
        private var description: String
        
        private var image: UIImage
        private let imageService: ImageService
        
        private var latestModel: BadgeDetailView.DataModel {
            get {
                return BadgeDetailView.DataModel(
                    title: title,
                    description: description,
                    image: image
                )
            }
        }
        
    }
}
