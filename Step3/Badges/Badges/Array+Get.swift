//
//  Array+Get.swift
//  Badges
//
//  Created by Pepas Personal on 2/15/16.
//  Copyright © 2016 Pepas Labs. All rights reserved.
//

import Foundation

extension Array
{
    func get(index: Int) -> Element?
    {
        guard index < count else { return nil }
        
        return self[index]
    }
}
