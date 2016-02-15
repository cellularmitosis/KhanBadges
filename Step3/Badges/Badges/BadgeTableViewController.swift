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

    // MARK: private implementation
    
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
            description: dto.translated_safe_extended_description,
            imageService: imageService)

        let navC = BadgeDetailViewController.instantiateInNavigationControllerFromStoryboard()
        let detailVC = navC.topViewController as! BadgeDetailViewController
        detailVC.dataService = service
        
        presentViewController(navC, animated: true, completion: nil)
    }
    
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

