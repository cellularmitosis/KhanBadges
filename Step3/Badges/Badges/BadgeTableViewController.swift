//
//  BadgeTableViewController.swift
//  Badges
//
//  Created by Pepas Personal on 2/11/16.
//  Copyright © 2016 Pepas Labs. All rights reserved.
//

import UIKit

class BadgeTableViewController: UITableViewController
{
    // MARK: public interface
    
    var dataSourceService: DataSourceService? {
        willSet {
            dataSourceService?.unsubscribe()
        }
        didSet {
            _applyDataSourceServiceIfViewLoaded()
        }
    }
    
    class func instantiateInNavigationControllerFromStoryboard(
        dataSourceService dataSourceService: BadgeTableViewController.DataSourceService) -> UINavigationController
    {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let navC = storyboard.instantiateViewControllerWithIdentifier("BadgeTableViewControllerNavigationController") as! UINavigationController
        
        let vc = navC.topViewController as! BadgeTableViewController
        vc.dataSourceService = dataSourceService
        
        return navC
    }

    deinit
    {
        dataSourceService?.unsubscribe()
    }
    
    // MARK: view lifecycle methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        FakeAnalytics.recordEvent("ListController.viewDidLoad")

        tableView.registerClass(BadgeTableViewCell.self, forCellReuseIdentifier: BadgeTableViewCell.reuseIdentifier)
        
        _applyDataSourceService()
        _applyDataSource()
    }
    
    private func _presentDetailController(indexPath: NSIndexPath)
    {
        guard let dto = badgeDataSource?.dataModelsService.dtos.get(indexPath.row) else
        {
            tableView.deselectSelectedCellIfNeeded(animated: true)
            return
        }
        
        let imageService = ServiceRepository.sharedInstance.imageServiceForURL(url: dto.iconUrl)
        
        let service = BadgeDetailViewController.DataModelService(
            title: dto.translated_description,
            description: description,
            imageService: imageService)

        let navC = BadgeDetailViewController.instantiateInNavigationControllerFromStoryboard()
        let detailVC = navC.topViewController as! BadgeDetailViewController
        detailVC.dataService = service
        
        presentViewController(navC, animated: true, completion: nil)
    }
    
    // MARK: private implementation
    
    private func _applyDataSourceServiceIfViewLoaded()
    {
        if isViewLoaded()
        {
            _applyDataSourceService()
        }
    }
    
    private func _applyDataSourceService()
    {
        let dataDidBecomeAvailableClosure: DataSourceClosure = ({ [weak self] (dataSource) -> () in
            guard let weakSelf = self else { return }
            
            weakSelf.badgeDataSource = dataSource
        })

        let didSelectRowClosure: DataSource.DidSelectBadgeCellClosure = ({ [weak self] (indexPath) -> () in
            guard let weakSelf = self else { return }
            
            weakSelf._presentDetailController(indexPath)
        })
        
        dataSourceService?.subscribeImmediate(
            tableView: self.tableView,
            didSelectRowClosure: didSelectRowClosure,
            dataDidBecomeAvailableClosure: dataDidBecomeAvailableClosure)
    }
    
    private var badgeDataSource: DataSource? {
        didSet {
            _applyDataSourceIfViewLoaded()
        }
    }
    
    private func _applyDataSourceIfViewLoaded()
    {
        if isViewLoaded()
        {
            _applyDataSource()
        }
    }
    
    private func _applyDataSource()
    {
        tableView.dataSource = badgeDataSource
        tableView.delegate = badgeDataSource
        tableView.reloadData()
    }
}


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
