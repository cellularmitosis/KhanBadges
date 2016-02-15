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
