//
//  ListController.swift
//  Badges
//
//  Created by Pepas Personal on 2/11/16.
//  Copyright © 2016 Pepas Labs. All rights reserved.
//

import UIKit

class ListController: UITableViewController
{
    // this selection chosen to represent all cases of line-length (for the english translations).
    let titles = [
        "Hour of Drawing with Code",
        "Collaborator",
        "Probability and statistics: Random variables and probability distributions",
        "Guru",
        "Precalculus: Probability and combinatorics",
        "Like Clockwork",
        "Apprentice Programmer",
        "Algebra II: Polynomial expressions, equations, and functions",
        "Tesla",
        "HTML/CSS: Making webpages",
    ]
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("ListCell")!

        let imageName = String(format: "Image-%i", indexPath.row % 19)
        cell.imageView?.image = UIImage(named: imageName)!
        
        cell.textLabel?.text = titles[indexPath.row % titles.count]
        
        return cell
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 246
    }
}

