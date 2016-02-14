//
//  UIFont+Scaled.swift
//  Badges
//
//  Created by Pepas Personal on 2/14/16.
//  Copyright © 2016 Pepas Labs. All rights reserved.
//

import UIKit

extension UIFont
{
    func scaled(factor: CGFloat) -> UIFont
    {
        let newPointSize = pointSize * factor
        return fontWithSize(newPointSize)
    }
}
