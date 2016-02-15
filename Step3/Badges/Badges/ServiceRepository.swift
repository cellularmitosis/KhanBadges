//
//  ServiceRepository.swift
//  Badges
//
//  Created by Pepas Personal on 2/14/16.
//  Copyright © 2016 Pepas Labs. All rights reserved.
//

import Foundation

class ServiceRepository
{
    // MARK: public interface
    
    static let sharedInstance = ServiceRepository()
    
    func resourceServiceForURL(url url: NSURL) -> ResourceService
    {
        if let service = resourceServices[url]
        {
            return service
        }
        else
        {
            let service = ResourceService(url: url)
            resourceServices[url] = service
            return service
        }
    }
    
    func imageServiceForURL(url url: NSURL) -> ImageService
    {
        if let service = imageServices[url]
        {
            return service
        }
        else
        {
            let resourceService = resourceServiceForURL(url: url)
            let imageService = ImageService(resourceService: resourceService)
            imageServices[url] = imageService
            return imageService
        }
    }
    
    func didReceiveMemoryWarning()
    {
        debugPrint("ServiceRepository.didReceiveMemoryWarning: (before) \(resourceServices.count) \(imageServices.count)")

        imageServices.forEach { (url, service) -> () in
            if service.subscriberCount() == 0
            {
                imageServices.removeValueForKey(url)
            }
            else
            {
                service.didReceiveMemoryWarning()
            }
        }

        resourceServices.forEach { (url, service) -> () in
            if service.subscriberCount() == 0
            {
                resourceServices.removeValueForKey(url)
            }
            else
            {
                service.didReceiveMemoryWarning()
            }
        }
        
        debugPrint("ServiceRepository.didReceiveMemoryWarning: (after) \(resourceServices.count) \(imageServices.count)")
    }
    
    func retryFailedRequests()
    {
        resourceServices.forEach { (url, service) -> () in
            service.retryFailedRequests()
        }
    }
    
    // MARK: private implementation
    
    private var resourceServices = [NSURL: ResourceService]()
    private var imageServices = [NSURL: ImageService]()
}
