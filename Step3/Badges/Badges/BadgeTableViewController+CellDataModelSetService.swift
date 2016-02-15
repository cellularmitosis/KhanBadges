//
//  BadgeTableViewController+CellDataModelSetService.swift
//  Badges
//
//  Created by Pepas Personal on 2/15/16.
//  Copyright © 2016 Pepas Labs. All rights reserved.
//

import Foundation

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
