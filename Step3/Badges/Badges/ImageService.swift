//
//  ImageService.swift
//  Badges
//
//  Created by Pepas Personal on 2/14/16.
//  Copyright © 2016 Pepas Labs. All rights reserved.
//

// TODO: change this into a subscription interface and intelligently handle e.g. coming back online?

import UIKit

class ResourceService
{
    typealias ResourceServiceResult = Result<NSData, ResourceService.Error>
    typealias ResourceServiceClosure = (ResourceServiceResult)->()
    
    enum Error: ErrorType
    {
        case NSURLSessionError(error: NSError)
    }

    typealias Subscriber = UnsafePointer<Void>
    typealias UrlString = String
    
    struct Subscription
    {
        let subscriber: Subscriber
        let urlString: UrlString
        let closure: ResourceServiceClosure
    }

    // note: this is effectively like a database of Subscription which is indexed on UrlString.
    // this means handling the result of a network request is fast, but removing a subscriber is expensive.
    private var subscriptions = [UrlString: [Subscription]]()
    
    func subscribe(subscriber subscriber: AnyObject, urlString: String, closure: ResourceServiceClosure)
    {
        let weakSubscriber = unsafeAddressOf(subscriber)
        
        let subscription = Subscription(
            subscriber: unsafeAddressOf(subscriber),
            urlString: urlString,
            closure: closure)

        _appendSubscription(subscription)
    }

    func unsubscribe(subscriber subscriber: Subscriber)
    {
        _removeAllSubscriptionsForSubscriber(subscriber)
    }
    
    private func _appendSubscription(subscription: Subscription)
    {
        var subscribers = subscriptions[subscription.urlString] ?? [Subscription]()
        subscribers.append(subscription)
        subscriptions[subscription.urlString] = subscribers
    }
    
    func _removeAllSubscriptionsForSubscriber(subscriber: Subscriber)
    {

    }
}

class ImageService
{
    static let sharedInstance = ImageService()
    
    typealias ImageServiceResult = Result<UIImage, ImageService.Error>
    typealias ImageServiceClosure = (result: ImageServiceResult)->()
    
    func fetch(urlString urlString: String, completion: ImageServiceClosure)
    {
        assert(NSThread.isMainThread())
        
        if let image = cachedImage(urlString: urlString)
        {
            // by contract the fetch() interface shall be asynchronous in all cases
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                completion(result: ImageServiceResult.Success(image))
            })
        }
        else if _requestIsAlreadyInFlight(urlString)
        {
            _appendClosureToInFlightRequests(urlString, completion: completion)
        }
        else
        {
            _startNewRequest(urlString, completion: completion)
        }
    }
    
    func cachedImage(urlString urlString: String) -> UIImage?
    {
        return cache[urlString]
    }
    
    func didReceiveMemoryWarning()
    {
        assert(NSThread.isMainThread())
        
        cache.removeAll()
    }
    
    private var cache = [String: UIImage]()
    private var inFlightRequests = [String: [ImageServiceClosure]]()
}

extension ImageService
{
    enum Error: ErrorType
    {
        case UknownError
        case NSURLSessionError(error: NSError)
        case UIImageInitFailed
    }
}

extension ImageService
{
    private func _appendClosureToInFlightRequests(urlString: String, completion: ImageServiceClosure)
    {
        if var closures = inFlightRequests[urlString]
        {
            closures.append(completion)
            inFlightRequests[urlString] = closures
        }
    }
    
    private func _requestIsAlreadyInFlight(urlString: String) -> Bool
    {
        return inFlightRequests[urlString] != nil
    }
    
    private func _startNewRequest(urlString: String, completion: ImageServiceClosure)
    {
        inFlightRequests[urlString] = [completion]
        
        let url = NSURL(string: urlString)!
        debugPrint("fetching \(urlString)")
        let task = NSURLSession.sharedSession().dataTaskWithURL(url) { [weak self] (data, response, error) -> Void in
            dispatch_async(dispatch_get_main_queue(), { [weak self] () -> Void in
                guard let weakSelf = self else { return }
                
                // assume we have one or the other
                assert(!(data == nil && error == nil))
                
                guard error == nil else
                {
                    weakSelf._requestDidFail(urlString: urlString, error: Error.NSURLSessionError(error: error!))
                    return
                }
                
                let assumedData = data!
                
                guard let image = UIImage(data: assumedData) else
                {
                    weakSelf._requestDidFail(urlString: urlString, error: Error.UIImageInitFailed)
                    return
                }
                
                weakSelf._requestDidSucceed(urlString, image: image)
                })
        }
        task.resume()
    }
    
    private func _requestDidSucceed(urlString: String, image: UIImage)
    {
        cache[urlString] = image
        let result = ImageServiceResult.Success(image)
        if let closures = inFlightRequests.removeValueForKey(urlString)
        {
            _callClosuresWithResult(closures, result: result)
        }
    }
    
    private func _requestDidFail(urlString urlString: String, error: ImageService.Error)
    {
        let result = ImageServiceResult.Failure(error)
        if let closures = inFlightRequests.removeValueForKey(urlString)
        {
            _callClosuresWithResult(closures, result: result)
        }
    }
    
    private func _callClosuresWithResult(closures: [ImageServiceClosure], result: ImageServiceResult)
    {
        for closure in closures
        {
            closure(result: result)
        }
    }
}
