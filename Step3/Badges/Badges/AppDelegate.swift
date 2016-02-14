//
//  AppDelegate.swift
//  Badges
//
//  Created by Pepas Personal on 2/11/16.
//  Copyright © 2016 Pepas Labs. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func applicationDidReceiveMemoryWarning(application: UIApplication) {
        ImageService.sharedInstance.didReceiveMemoryWarning()
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
