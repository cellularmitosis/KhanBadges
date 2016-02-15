//
//  ResourceService.swift
//  Badges
//
//  Created by Pepas Personal on 2/14/16.
//  Copyright © 2016 Pepas Labs. All rights reserved.
//

import UIKit

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
    
    var cachedValue: NSData? {
        get {
            return cache?.value
        }
    }
    
    enum Error: ErrorType
    {
        case NSURLSessionFailed(error: NSError)
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
}

// MARK: private methods
extension ResourceService
{
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
                weakSelf.requestInFlight = false
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
                    let serviceError = Error.NSURLSessionFailed(error: error)
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

