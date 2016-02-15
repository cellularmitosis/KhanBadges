//
//  BadgeTableViewController.swift
//  Badges
//
//  Created by Pepas Personal on 2/11/16.
//  Copyright © 2016 Pepas Labs. All rights reserved.
//

import UIKit

extension UITableView
{
    func deselectSelectedCellIfNeeded(animated animated: Bool)
    {
        guard let indexPath = indexPathForSelectedRow else { return }
        deselectRowAtIndexPath(indexPath, animated: animated)
    }
}

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

struct BadgeDTO
{
    let name: String
    let translated_description: String
    let translated_safe_extended_description: String
    let iconUrl: NSURL
}

extension BadgeTableViewController
{
    typealias CellDataModelSetClosure = ((dataModels: [BadgeTableViewCellDataModelProtocol], changeList: [NSIndexPath]))->()
    
    class CellDataModelSetService
    {
        // MARK: public interface 
        
        private(set) var dtos: [BadgeDTO]
        
        init(dtos: [BadgeDTO], serviceRepository: ServiceRepository)
        {
            self.dtos = dtos
            
            self.dataModels = dtos.map({ (dto) -> BadgeTableViewCellDataModelProtocol in
                return BadgeTableViewCell.PartialDataModel(dto: dto)
            })
            
            self.serviceRepository = serviceRepository
        }
        
        func subscribeImmediate(dataDidUpdateClosure: CellDataModelSetClosure)
        {
            closure = dataDidUpdateClosure
            closure?((dataModels: dataModels, changeList: []))
        }
        
        func unsubscribe()
        {
            closure = nil
        }

        func shouldFetchImageAtIndexPath(indexPath: NSIndexPath)
        {
            debugPrint("shouldFetchImageAtIndexPath \(indexPath.row)")
            
            guard let dto = dtos.get(indexPath.row) else { return }
            
            let url = dto.iconUrl
            let imageService = serviceRepository.imageServiceForURL(url: url)
            imageServices[indexPath] = imageService
            
            imageService.subscribeAsync(subscriber: indexPath) { [weak self] (result) -> () in
                
                guard
                    let weakSelf = self,
                    let closure = weakSelf.closure,
                    case .Success(let image) = result
                else
                {
                    return
                }
                
                // FIXME this is what I want:
                //
                //   guard (let a, var b) = foo()
                //
                // but the compiler doesn't like it.
                // what's the closest I can get to that?
                
                guard var (partialModel, trimmedModels) = weakSelf._extractPartialDataModelForDTO(dto) else { return }

                let completeModel = BadgeTableViewCell.CompleteDataModel(
                    partialModel: partialModel,
                    image: image)

                trimmedModels.insert(completeModel, atIndex: indexPath.row)
                weakSelf.dataModels = trimmedModels

                closure((dataModels: weakSelf.dataModels, changeList: [indexPath]))
                
                weakSelf.imageServices[indexPath]?.unsubscribe(subscriber: indexPath)
            }
        }
        
        // MARK: private implementation
        
        private var dataModels: [BadgeTableViewCellDataModelProtocol]
        private let serviceRepository: ServiceRepository
        private var closure: CellDataModelSetClosure?
        private var imageServices = [NSIndexPath: ImageService]()
        
        private func _extractPartialDataModelForDTO(dto: BadgeDTO) -> (BadgeTableViewCell.PartialDataModel, [BadgeTableViewCellDataModelProtocol])?
        {
            var extractedModel: BadgeTableViewCell.PartialDataModel?
            
            let trimmedDataModels = dataModels.filter({ (model) -> Bool in
                
                if let partialModel = model as? BadgeTableViewCell.PartialDataModel
                    where partialModel.id == dto.name
                {
                    extractedModel = partialModel
                    return false
                }
                else
                {
                    return true
                }
                
            })

            guard let model = extractedModel else { return nil }
            
            return (model, trimmedDataModels)
        }
    }
}

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
            
            debugPrint("willDisplay row \(indexPath.row), title: \(model.title)")
            
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
            
            debugPrint("reloadRowsAtIndexPaths: \(changeList[0].row)")
            tableView?.reloadRowsAtIndexPaths(changeList, withRowAnimation: UITableViewRowAnimation.Fade)
        }
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
