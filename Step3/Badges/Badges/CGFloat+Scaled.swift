//
//  CGFloat+Scaled.swift
//  Badges
//
//  Created by Pepas Personal on 2/14/16.
//  Copyright © 2016 Pepas Labs. All rights reserved.
//

import UIKit

extension CGFloat
{
    func scaled(factor: CGFloat) -> CGFloat
    {
        return round(self * factor)
    }
}
