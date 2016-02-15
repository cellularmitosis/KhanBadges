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
        self.service = resourceService
    }
    
    func subscribeImmediate(subscriber subscriber: AnyObject, closure: ImageServiceClosure)
    {
        service.subscribeImmediate(subscriber: subscriber, closure: { (result)->() in

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
    
    func unsubscribe(subscriber subscriber: AnyObject)
    {
        service.unsubscribe(subscriber: subscriber)
    }
    
    enum Error: ErrorType
    {
        case UIImageInitFailed
        case ResourceServiceFailed(error: ResourceService.Error)
    }

    // MARK: private implementation
    
    private let service: ResourceService
}
