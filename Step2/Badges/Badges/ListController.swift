//
//  ListController.swift
//  Badges
//
//  Created by Pepas Personal on 2/11/16.
//  Copyright © 2016 Pepas Labs. All rights reserved.
//

import UIKit

var json: [AnyObject]?

class ListController: UITableViewController
{
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        guard json == nil else { return }
        
        let urlString = "https://www.khanacademy.org/api/v1/badges"
        let url = NSURL(string: urlString)!
        let task = NSURLSession.sharedSession().dataTaskWithURL(url) { [weak self] (data, response, error) -> Void in
            guard let data = data else { return }

            dispatch_async(dispatch_get_main_queue(), { [weak self] () -> Void in
                guard let weakSelf = self else { return }

                json = try! NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions()) as! [AnyObject]
                weakSelf.tableView.reloadData()
            })
        }
        task.resume()
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("ListCell")!

        let imageName = String(format: "Image-%i", indexPath.row % 19)
        cell.imageView?.image = UIImage(named: imageName)!

        let dict: [String: AnyObject] = json![indexPath.row] as! [String: AnyObject]
        let text: String = dict["description"] as! String
        cell.textLabel?.text = text
        
        return cell
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = json?.count ?? 0
        return count
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let cell = sender as! UITableViewCell
        let navC = segue.destinationViewController as! UINavigationController
        let detailVC = navC.topViewController as! DetailViewController
        let _ = detailVC.view
        
        detailVC.titleLabel.text = cell.textLabel?.text
        detailVC.imageView.image = cell.imageView?.image
        
        let indexPath = self.tableView.indexPathForCell(cell)!
        let dict: [String: AnyObject] = json![indexPath.row] as! [String: AnyObject]
        let text: String = dict["translated_safe_extended_description"] as! String
        detailVC.descriptionLabel.text = text
    }
}

