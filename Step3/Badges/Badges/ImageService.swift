//
//  ImageService.swift
//  Badges
//
//  Created by Pepas Personal on 2/14/16.
//  Copyright © 2016 Pepas Labs. All rights reserved.
//

import UIKit

class ImageService
{
    // MARK: public interface
    
    typealias ImageServiceResult = Result<UIImage, ImageService.Error>
    typealias ImageServiceClosure = (result: ImageServiceResult)->()

    init(resourceService: ResourceService)
    {
        debugPrint("ImageService.init(), url: \(resourceService.url)")
        self.resourceService = resourceService
    }
    
    deinit
    {
        debugPrint("\(self): \(__FUNCTION__)")
    }

    func subscribeImmediate(subscriber subscriber: AnyObject, closure: ImageServiceClosure)
    {
        resourceService.subscribeImmediate(subscriber: subscriber, closure: { (result)->() in

            switch result
            {
            case .Success(let data):
                guard let image = UIImage(data: data) else
                {
                    let result: ImageServiceResult = .Failure(Error.UIImageInitFailed)
                    closure(result: result)
                    return
                }
                
                let result: ImageServiceResult = .Success(image)
                closure(result: result)

            case .Failure(let resourceServiceError):
                let error: Error = .ResourceServiceFailed(error: resourceServiceError)
                let result: ImageServiceResult = .Failure(error)
                closure(result: result)
            }
        })
    }
    
    func subscribeAsync(subscriber subscriber: AnyObject, closure: ImageServiceClosure)
    {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            self.subscribeImmediate(subscriber: subscriber, closure: closure)
        }
    }
    
    func unsubscribe(subscriber subscriber: AnyObject)
    {
        resourceService.unsubscribe(subscriber: subscriber)
    }
    
    var cachedValue: UIImage? {
        get {
            guard let data = resourceService.cachedValue else
            {
                return nil
            }
            return UIImage(data: data)
        }
    }
    
    enum Error: ErrorType
    {
        case UIImageInitFailed
        case ResourceServiceFailed(error: ResourceService.Error)
    }

    // MARK: maintenance interface
    
    func didReceiveMemoryWarning()
    {
        // empty for now.  perhaps we will add non-computed cache later.
    }
    
    func subscriberCount() -> Int
    {
        return resourceService.subscriberCount()
    }
    
    // MARK: private implementation
    
    private let resourceService: ResourceService
}
