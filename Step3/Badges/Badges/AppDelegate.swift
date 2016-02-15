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
    var reachability: Reachability?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {

        _setupReachability()
        
        let url = NSURL(string: "https://www.khanacademy.org/api/v1/badges")!
        let resourceService = ServiceRepository.sharedInstance.resourceServiceForURL(url: url)
        let dataSourceService = BadgeTableViewController.DataSourceService(resourceService: resourceService, serviceRepository: ServiceRepository.sharedInstance)
        let navController = BadgeTableViewController.instantiateInNavigationControllerFromStoryboard(dataSourceService: dataSourceService)
        
        window = UIWindow(frame: UIScreen.mainScreen().bounds)
        window?.rootViewController = navController
        window?.makeKeyAndVisible()
        
        return true
    }

    private func _setupReachability()
    {
        do
        {
            reachability = try Reachability.reachabilityForInternetConnection()
            reachability?.whenReachable = { reachability in
                dispatch_async(dispatch_get_main_queue(), { [weak self] () -> Void in
                    guard let weakSelf = self else { return }
                    weakSelf.applicationDidComeOnline()
                    })
            }
            try reachability?.startNotifier()
        } catch {}
    }
    
    func applicationDidComeOnline()
    {
        ServiceRepository.sharedInstance.retryFailedRequests()
    }
    
    func applicationWillEnterForeground(application: UIApplication)
    {
        ServiceRepository.sharedInstance.retryFailedRequests()
    }

    func applicationDidReceiveMemoryWarning(application: UIApplication)
    {
        ServiceRepository.sharedInstance.didReceiveMemoryWarning()
    }
}

