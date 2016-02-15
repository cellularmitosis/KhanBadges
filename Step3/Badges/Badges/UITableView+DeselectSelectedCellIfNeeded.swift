//
//  UITableView+DeselectSelectedCellIfNeeded.swift
//  Badges
//
//  Created by Pepas Personal on 2/15/16.
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

