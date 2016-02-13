//
//  ListController.swift
//  Badges
//
//  Created by Pepas Personal on 2/11/16.
//  Copyright © 2016 Pepas Labs. All rights reserved.
//

import UIKit

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

let descriptions = [
    "Achieve mastery in all skills in Probability and statistics: Random variables and probability distributions",
    "Evaluate 30 projects",
    "Complete the OO design tutorial in Intro to JS",
    "Ask 100 questions that earn 3+ votes",
    "Achieve mastery in all skills in 6th grade (U.S.): Geometry",
    "Complete a coding challenge",
    "Quickly & correctly answer 5 skill problems in a row (time limit depends on skill difficulty)",
    "Support Khan Academy with a donation in 2015",
]

class ListController: UITableViewController
{
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
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let cell = sender as! UITableViewCell
        let detailVC = segue.destinationViewController as! DetailViewController
        let _ = detailVC.view
        
        detailVC.titleLabel.text = cell.textLabel?.text
        detailVC.imageView.image = cell.imageView?.image
        
        let indexPath = self.tableView.indexPathForCell(cell)!
        detailVC.descriptionLabel.text = descriptions[indexPath.row % descriptions.count]
    }
}

