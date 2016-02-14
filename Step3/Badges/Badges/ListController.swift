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
    override func viewDidLoad() {
        super.viewDidLoad()
        FakeAnalytics.recordEvent("ListController.viewDidLoad")
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        guard json == nil else { return }
        
        let urlString = "https://www.khanacademy.org/api/v1/badges"
        let url = NSURL(string: urlString)!
        debugPrint("fetching \(urlString)")
        let task = NSURLSession.sharedSession().dataTaskWithURL(url) { [weak self] (data, response, error) -> Void in
            guard let data = data else { return }

            dispatch_async(dispatch_get_main_queue(), { [weak self] () -> Void in
                guard let weakSelf = self else { return }

                json = try! NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions()) as! [AnyObject]
                json = json?.filter({ (element) -> Bool in
                    return element["badge_category"] as! Int == 5
                })
                
                weakSelf.tableView.reloadData()
            })
        }
        task.resume()
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("ListCell")!
        cell.textLabel?.text = ""
        cell.imageView?.image = UIImage(named: "question_mark.png")
        return cell
    }
    
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        
        let dict: [String: AnyObject] = json![indexPath.row] as! [String: AnyObject]
        
        let text: String = dict["description"] as! String
        cell.textLabel?.text = text
        
        let iconUrlStrings: [String:String] = dict["icons"] as! [String:String]
        let urlString = iconUrlStrings["large"]!
        
        if let icon = ImageService.sharedInstance.cachedImage(urlString: urlString)
        {
            cell.imageView?.image = icon
        }
        else
        {
            ImageService.sharedInstance.fetch(urlString: urlString, completion: { [weak self] (result) -> () in
                guard let weakSelf = self else { return }
                
                if case .Success(_) = result
                {
                    weakSelf.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .None)
                }
            })
        }
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = json?.count ?? 0
        return count
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        let cell = sender as! UITableViewCell
        let navC = segue.destinationViewController as! UINavigationController
        let detailVC = navC.topViewController as! DetailViewController

        let title: String = cell.textLabel!.text!
        
        let indexPath = self.tableView.indexPathForCell(cell)!
        let dict: [String: AnyObject] = json![indexPath.row] as! [String: AnyObject]
        let description: String = dict["translated_safe_extended_description"] as! String

        let iconUrlStrings: [String:String] = dict["icons"] as! [String:String]
        let urlString = iconUrlStrings["large"]!

        let service = DetailViewController.DataModelService(
            title: title,
            description: description,
            imageUrlString: urlString,
            imageService: ImageService.sharedInstance)
        
        detailVC.dataService = service
    }
}

