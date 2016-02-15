//
//  BadgeTableViewController+DataSource.swift
//  Badges
//
//  Created by Pepas Personal on 2/15/16.
//  Copyright © 2016 Pepas Labs. All rights reserved.
//

import UIKit

extension BadgeTableViewController
{
    class DataSource: NSObject, UITableViewDataSource, UITableViewDelegate
    {
        typealias DidSelectBadgeCellClosure = (NSIndexPath)->()
        
        // MARK: public interface
        
        let dataModelsService: BadgeTableViewController.CellDataModelSetService
        
        init(dataModelsService: BadgeTableViewController.CellDataModelSetService, tableView: UITableView, didSelectRowClosure: DidSelectBadgeCellClosure)
        {
            self.dataModelsService = dataModelsService
            self.tableView = tableView
            self.didSelectRowClosure = didSelectRowClosure
            super.init()
            
            self.dataModelsService.subscribeImmediate { [weak self] (dataModels, changeList) -> () in
                guard let weakSelf = self else { return }
                
                weakSelf._dataDidArrive(dataModels, changeList: changeList)
            }
        }
        
        deinit
        {
            self.dataModelsService.unsubscribe()
        }
        
        // MARK: table view methods
        
        func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
        {
            return dataModels.count
        }
        
        func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
        {
            let cell = tableView.dequeueReusableCellWithIdentifier(BadgeTableViewCell.reuseIdentifier)!
            return cell
        }
        
        func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath)
        {
            guard
                let model = dataModels.get(indexPath.row),
                let badgeCell = cell as? BadgeTableViewCell
                else
            {
                return
            }
            
            if model is BadgeTableViewCell.PartialDataModel
            {
                dataModelsService.shouldFetchImageAtIndexPath(indexPath)
            }
            
            badgeCell.dataModel = model
        }
        
        func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
        {
            didSelectRowClosure(indexPath)
        }
        
        // MARK: private implementation
        
        private var dataModels = [BadgeTableViewCellDataModelProtocol]()
        private weak var tableView: UITableView?
        private var didSelectRowClosure: DidSelectBadgeCellClosure
        
        private func _dataDidArrive(dataModels: [BadgeTableViewCellDataModelProtocol], changeList: [NSIndexPath])
        {
            let oldCount = self.dataModels.count
            let newCount = dataModels.count
            
            self.dataModels = dataModels
            
            guard oldCount == newCount else
            {
                tableView?.reloadData()
                return
            }
            
            tableView?.reloadRowsAtIndexPaths(changeList, withRowAnimation: UITableViewRowAnimation.Fade)
        }
    }
}

// Note: the swift compiler segfaults if you try to extract this into its own file.
extension BadgeTableViewController
{
    typealias DataSourceClosure = (BadgeTableViewController.DataSource)->()
    
    class DataSourceService
    {
        private let resourceService: ResourceService
        private let serviceRepository: ServiceRepository
        private var cache: BadgeTableViewController.DataSource?
        
        init(resourceService: ResourceService, serviceRepository: ServiceRepository)
        {
            self.resourceService = resourceService
            self.serviceRepository = serviceRepository
        }
        
        func subscribeImmediate(
            tableView tableView: UITableView,
            didSelectRowClosure: DataSource.DidSelectBadgeCellClosure,
            dataDidBecomeAvailableClosure: DataSourceClosure)
        {
            closure = dataDidBecomeAvailableClosure
            
            resourceService.subscribeImmediate(subscriber: self) { [weak self, weak tableView] (result) -> () in
                guard
                    let weakSelf = self,
                    let tableView = tableView
                    else
                {
                    return
                }
                
                guard
                    case .Success(let data) = result,
                    let maybeBadgeDicts: [AnyObject]? = try? NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions()) as? [AnyObject],
                    let allBadgeDicts = maybeBadgeDicts
                    else
                {
                    return
                }
                
                let patchDicts: [AnyObject] = allBadgeDicts.filter({ (dict) -> Bool in
                    guard let category: Int = dict["badge_category"] as? Int else { return false }
                    return category == 5
                })
                
                var dtos = [BadgeDTO]()
                patchDicts.forEach({ (object) -> () in
                    
                    guard
                        let jsonDict = object as? [String:AnyObject],
                        let name: String = jsonDict["name"] as? String,
                        let translated_description: String = jsonDict["translated_description"] as? String,
                        let translated_safe_extended_description: String = jsonDict["translated_safe_extended_description"] as? String,
                        let iconUrlStrings: [String: String] = jsonDict["icons"] as? [String:String],
                        let iconUrlString: String = iconUrlStrings["large"],
                        let iconUrl: NSURL = NSURL(string: iconUrlString)
                        else
                    {
                        return
                    }
                    
                    let dto = BadgeDTO(
                        name: name,
                        translated_description: translated_description,
                        translated_safe_extended_description: translated_safe_extended_description,
                        iconUrl: iconUrl)
                    
                    dtos.append(dto)
                })
                
                let dataModelsService = BadgeTableViewController.CellDataModelSetService(
                    dtos: dtos,
                    serviceRepository: weakSelf.serviceRepository)
                
                let dataSource = BadgeTableViewController.DataSource(
                    dataModelsService: dataModelsService,
                    tableView: tableView,
                    didSelectRowClosure: didSelectRowClosure)
                
                weakSelf.closure?(dataSource)
            }
        }
        
        func unsubscribe()
        {
            resourceService.unsubscribe(subscriber: self)
            closure = nil
        }
        
        private var closure: DataSourceClosure?
    }
}
