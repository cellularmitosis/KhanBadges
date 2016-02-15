//
//  BadgeTableViewController.swift
//  Badges
//
//  Created by Pepas Personal on 2/11/16.
//  Copyright © 2016 Pepas Labs. All rights reserved.
//

import UIKit

var json: [AnyObject]?

class BadgeTableViewController: UITableViewController
{
    class func instantiateFromStoryboard() -> BadgeTableViewController
    {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewControllerWithIdentifier("ListController") as! BadgeTableViewController
        return vc
    }
    
    class func instantiateInNavigationControllerFromStoryboard() -> UINavigationController
    {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let navC = storyboard.instantiateViewControllerWithIdentifier("ListNavController") as! UINavigationController
        return navC
    }
    
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
        let url = NSURL(string: urlString)!
        
        let imageService = ServiceRepository.sharedInstance.imageServiceForURL(url: url)
        
        if let cachedImage = imageService.cachedValue
        {
            cell.imageView?.image = cachedImage
        }
        else
        {
            // we use subscribeAsync to guarantee we don't get an immediate return.
            // if we did, reloadRowsAtIndexPaths would crash the app.
            imageService.subscribeAsync(subscriber: self) { [weak tableView] (result) -> () in
                guard let weakTableView = tableView else { return }
                
                if case .Success(_) = result
                {
                    weakTableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .None)
                }
            }
        }
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = json?.count ?? 0
        return count
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        let cell = sender as! UITableViewCell
        let navC = segue.destinationViewController as! UINavigationController
        let detailVC = navC.topViewController as! BadgeDetailViewController

        let title: String = cell.textLabel!.text!
        
        let indexPath = self.tableView.indexPathForCell(cell)!
        let dict: [String: AnyObject] = json![indexPath.row] as! [String: AnyObject]
        let description: String = dict["translated_safe_extended_description"] as! String

        let iconUrlStrings: [String:String] = dict["icons"] as! [String:String]
        let urlString = iconUrlStrings["large"]!
        let url = NSURL(string: urlString)!
        
        let imageService = ServiceRepository.sharedInstance.imageServiceForURL(url: url)

        let service = BadgeDetailViewController.DataModelService(
            title: title,
            description: description,
            imageService: imageService)
        
        detailVC.dataService = service
    }
}

