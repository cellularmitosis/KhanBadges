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
    
    let url: NSURL

    init(url: NSURL)
    {
        debugPrint("ResourceService.init(): \(url.path?.componentsSeparatedByString("/").last))")
        self.url = url
    }
    
    deinit
    {
        debugPrint("ResourceService.deinit(): \(url.path?.componentsSeparatedByString("/").last))")
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
    
    func retryFailedRequests()
    {
        _retryFailedRequestsIfNeeded()
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
        var closuresToCall = [ResourceServiceClosure]()
        
        switch result
        {
        case .Success(_):
            cache = result
            closuresToCall = _allClosures()
            
        case .Failure(_):
            cache = nil
            closuresToCall = _closuresWhichHaveNotAlreadyBeenGivenAFailureResult()
            _markAllSubscriptionsFailed()
        }
        
        _callClosuresWithResult(closuresToCall, result: result)
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

    private func _subscriptionsInAFailureStateExist() -> Bool
    {
        let failuresExist = subscriptions.reduce(false, combine: { (previousAnswer, kvTuple: (Subscriber, Subscription)) -> Bool in
            guard previousAnswer == false else { return true }
            let subscription = kvTuple.1
            return subscription.lastResultGiven == .Failure
        })
        return failuresExist
    }
    
    private func _retryFailedRequestsIfNeeded()
    {
        if _subscriptionsInAFailureStateExist()
        {
            _startNewRequestIfNotAlreadyInFlight()
        }
    }
}

