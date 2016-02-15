//
//  ImageService.swift
//  Badges
//
//  Created by Pepas Personal on 2/14/16.
//  Copyright © 2016 Pepas Labs. All rights reserved.
//

// TODO: change this into a subscription interface and intelligently handle e.g. coming back online?

import UIKit

class ResourceServiceRepository
{
    static let sharedInstance = ResourceServiceRepository()
    
    private var services = [NSURL: ResourceService]()
    
    func serviceForURL(url url: NSURL) -> ResourceService
    {
        if let service = services[url]
        {
            return service
        }
        else
        {
            let service = ResourceService(url: url)
            services[url] = service
            return service
        }
    }
    
    func didReceiveMemoryWarning()
    {
        services.forEach { (url, service) -> () in
            if service.subscriberCount() == 0
            {
                services.removeValueForKey(url)
            }
            else
            {
                service.didReceiveMemoryWarning()
            }
        }
    }
}

class ResourceService
{
    // MARK: public interface
    
    typealias ResourceServiceResult = Result<NSData, ResourceService.Error>
    typealias ResourceServiceClosure = (ResourceServiceResult)->()

    init(url: NSURL)
    {
        self.url = url
    }

    func subscribeImmediate(subscriber subscriber: AnyObject, closure: ResourceServiceClosure)
    {
        assert(NSThread.isMainThread())

        let weakSubscriber = unsafeAddressOf(subscriber)
        let subscription = Subscription(closure: closure)
        _addSubscriber(weakSubscriber, subscription: subscription)
        
        if let cache = cache
        {
            closure(cache)
        }
        else
        {
            _startNewRequestIfNotAlreadyInFlight()
        }
    }
    
    func unsubscribe(subscriber subscriber: AnyObject)
    {
        assert(NSThread.isMainThread())
        let weakSubscriber = unsafeAddressOf(subscriber)
        _removeSubscriber(weakSubscriber)
    }
    
    enum Error: ErrorType
    {
        case NSURLSessionError(error: NSError)
    }
    
    // MARK: maintenance interface
    
    func didReceiveMemoryWarning()
    {
        cache = nil
    }
    
    func subscriberCount() -> Int
    {
        return subscriptions.count
    }
    
    // MARK: private implementation

    private typealias Subscriber = UnsafePointer<Void>

    private enum ResultTypeGiven
    {
        case Success
        case Failure
    }
    
    private struct Subscription
    {
        let closure: ResourceServiceClosure
        var lastResultGiven: ResultTypeGiven?
        
        init(closure: ResourceServiceClosure)
        {
            self.closure = closure
            self.lastResultGiven = nil
        }
    }

    private let url: NSURL
    private var subscriptions = [Subscriber: Subscription]()
    private var requestInFlight = false
    private var cache: ResourceServiceResult?
    
    private func _addSubscriber(subscriber: Subscriber, subscription: Subscription)
    {
        subscriptions[subscriber] = subscription
    }
    
    private func _removeSubscriber(subscriber: Subscriber)
    {
        subscriptions.removeValueForKey(subscriber)
    }
    
    private func _startNewRequestIfNotAlreadyInFlight()
    {
        if requestInFlight == false
        {
            requestInFlight = true
            
            _startNewRequest({ [weak self] (result) -> () in
                guard let weakSelf = self else { return }
                weakSelf._requestDidFinish(result)
            })
        }
    }
    
    private func _startNewRequest(closure: ResourceServiceClosure)
    {
        let task = NSURLSession.sharedSession().dataTaskWithURL(url) { (data, response, error) -> Void in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                
                // assume we have one or the other
                assert(!(data == nil && error == nil))

                if let error = error
                {
                    let serviceError = Error.NSURLSessionError(error: error)
                    let result = ResourceServiceResult.Failure(serviceError)
                    closure(result)
                }
                else
                {
                    let assumedData = data!
                    let result = ResourceServiceResult.Success(assumedData)
                    closure(result)
                }
            })
        }
        task.resume()
    }

    private func _requestDidFinish(result: ResourceServiceResult)
    {
        var closures = [ResourceServiceClosure]()
        
        switch result
        {
        case .Success(_):
            cache = result
            closures = _allClosures()
            
        case .Failure(_):
            cache = nil
            closures = _closuresWhichHaveNotAlreadyBeenGivenAFailureResult()
            _markAllSubscriptionsFailed()
        }
        
        _callClosuresWithResult(closures, result: result)
    }
    
    private func _allClosures() -> [ResourceServiceClosure]
    {
        return subscriptions.map { (key, value) -> ResourceServiceClosure in
            return value.closure
        }
    }
    
    private func _closuresWhichHaveNotAlreadyBeenGivenAFailureResult() -> [ResourceServiceClosure]
    {
        return subscriptions.filter({ (subscriber, subscription) -> Bool in
            return subscription.lastResultGiven == .Failure
        }).map({ (subscriber, subscription) -> ResourceServiceClosure in
            return subscription.closure
        })
    }
    
    private func _markAllSubscriptionsFailed()
    {
        subscriptions.forEach { (subscriber, subscription) -> () in
            if subscription.lastResultGiven != .Failure
            {
                var mutatedSubscription = subscription
                mutatedSubscription.lastResultGiven = .Failure
                subscriptions[subscriber] = mutatedSubscription
            }
        }
    }
    
    private func _callClosuresWithResult(closures: [ResourceServiceClosure], result: ResourceServiceResult)
    {
        for closure in closures
        {
            closure(result)
        }
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
