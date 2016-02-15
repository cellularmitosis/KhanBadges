//
//  BadgeTableViewController.swift
//  Badges
//
//  Created by Pepas Personal on 2/11/16.
//  Copyright © 2016 Pepas Labs. All rights reserved.
//

import UIKit

struct BadgeDTO
{
    let translated_description: String
    let translated_safe_extended_description: String
    let iconUrl: NSURL
}

class BadgeTableViewController: UITableViewController
{
    var dataSourceService: DataSourceService? {
        didSet {
            dataSourceService?.subscribeImmediate({ [weak self] (dataSource) -> () in
                guard let weakSelf = self else { return }
                
                weakSelf.badgeDataSource = dataSource
            })
        }
    }
    
    var badgeDataSource: DataSource? {
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
    
    class func instantiateInNavigationControllerFromStoryboard(
        dataSourceService dataSourceService: BadgeTableViewController.DataSourceService) -> UINavigationController
    {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let navC = storyboard.instantiateViewControllerWithIdentifier("BadgeTableViewControllerNavigationController") as! UINavigationController
        let vc = navC.topViewController as! BadgeTableViewController
        vc.dataSourceService = dataSourceService
        return navC
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        FakeAnalytics.recordEvent("ListController.viewDidLoad")

        tableView.registerClass(BadgeTableViewCell.self, forCellReuseIdentifier: BadgeTableViewCell.reuseIdentifier)
        
        _applyDataSource()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
//        let cell = sender as! UITableViewCell
//        let navC = segue.destinationViewController as! UINavigationController
//        let detailVC = navC.topViewController as! BadgeDetailViewController
//
//        let title: String = cell.textLabel!.text!
//        
//        let indexPath = self.tableView.indexPathForCell(cell)!
//        let dict: [String: AnyObject] = json![indexPath.row] as! [String: AnyObject]
//        let description: String = dict["translated_safe_extended_description"] as! String
//
//        let iconUrlStrings: [String:String] = dict["icons"] as! [String:String]
//        let urlString = iconUrlStrings["large"]!
//        let url = NSURL(string: urlString)!
//        
//        let imageService = ServiceRepository.sharedInstance.imageServiceForURL(url: url)
//
//        let service = BadgeDetailViewController.DataModelService(
//            title: title,
//            description: description,
//            imageService: imageService)
//        
//        detailVC.dataService = service
    }
}

extension Array
{
    func get(index: Int) -> Element?
    {
        guard index < count else { return nil }
        
        return self[index]
    }
}

class BadgeTableViewDataSource: NSObject, UITableViewDataSource, UITableViewDelegate
{
    private var dataModels = [BadgeTableViewCellDataModelProtocol]()
    private let dataModelsService: BadgeTableViewController.CellDataModelSetService
    
    init(dataModelsService: BadgeTableViewController.CellDataModelSetService)
    {
        self.dataModelsService = dataModelsService
        
        self.dataModelsService.subscribeImmediate { [weak self] (dataModels, changeList) -> () in
            guard let weakSelf = self else { return }
            
            weakSelf._dataDidArrive(dataModels, changeList: changeList)
        }
    }

    private func _dataDidArrive(dataModels: [BadgeTableViewCellDataModelProtocol], changeList: [NSIndexPath])
    {
        
    }

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
        
        if let partialModel = model as? BadgeTableViewCell.PartialDataModel
        {
            // FIXME notify the data set service that we need to fetch the image at this indexPath
        }
        
        badgeCell.applyDataModel(model)
    }
}

extension BadgeTableViewController
{
    typealias CellDataModelSetClosure = ((dataModels: [BadgeTableViewCellDataModelProtocol], changeList: [NSIndexPath]))->()

    class CellDataModelSetService
    {
        private let dtos: [BadgeDTO]
        
        init(dtos: [BadgeDTO])
        {
            self.dtos = dtos
        }
        
        func subscribeImmediate(dataDidUpdateClosure: CellDataModelSetClosure)
        {

        }
        
        func unsubscribe()
        {
            
        }
    }
}

extension BadgeTableViewController
{
    typealias DataSourceClosure = (BadgeTableViewDataSource)->()
    
    class DataSourceService
    {
        private let resourceService: ResourceService
        private var cache: BadgeTableViewDataSource?
        
        init(resourceService: ResourceService)
        {
            self.resourceService = resourceService
        }
        
        func subscribeImmediate(dataDidBecomeAvailableClosure: DataSourceClosure)
        {
            closure = dataDidBecomeAvailableClosure
            
            resourceService.subscribeImmediate(subscriber: self) { [weak self] (result) -> () in
                guard let weakSelf = self else { return }
                
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
                        translated_description: translated_description,
                        translated_safe_extended_description: translated_safe_extended_description,
                        iconUrl: iconUrl)
                    
                    dtos.append(dto)
                })
                
                let dataSource = BadgeTableViewController.DataSource(jsonData: dtos)
                
                weakSelf.closure?(dataSource)
            }
        }
        
        class DataSourceFactory
        {
            private let dtos: [BadgeDTO]
            
            init(dtos: [BadgeDTO])
            {
                self.dtos = dtos
            }
            
            
        }
        
        func unsubscribe()
        {
            closure = nil
        }
        
        private var closure: DataSourceClosure?
    }
}
