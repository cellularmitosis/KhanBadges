//
//  UIScreen+Width.swift
//  Badges
//
//  Created by Pepas Personal on 2/14/16.
//  Copyright © 2016 Pepas Labs. All rights reserved.
//

import UIKit

extension UIScreen
{
    class func width() -> CGFloat
    {
        // Note: this will return e.g. 320 regardless of what orientation the phone is currently held.
        return UIScreen.mainScreen().bounds.size.width
    }
}
