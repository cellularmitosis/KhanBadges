//
//  ListController.swift
//  Badges
//
//  Created by Pepas Personal on 2/11/16.
//  Copyright © 2016 Pepas Labs. All rights reserved.
//

import UIKit

var json: [AnyObject]?
var icons = [UIImage?]()

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
                
                while icons.count < json?.count
                {
                    icons.append(nil)
                }
                
                weakSelf.tableView.reloadData()
            })
        }
        task.resume()
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("ListCell")!

        let dict: [String: AnyObject] = json![indexPath.row] as! [String: AnyObject]
        
        let text: String = dict["description"] as! String
        cell.textLabel?.text = text

        if let icon = icons[indexPath.row]
        {
            cell.imageView?.image = icon
        }
        else
        {
            let iconUrlStrings: [String:String] = dict["icons"] as! [String:String]
            let urlString = iconUrlStrings["large"]!
            let url = NSURL(string: urlString)!
            debugPrint("fetching \(urlString)")
            let task = NSURLSession.sharedSession().dataTaskWithURL(url) { [weak self] (data, response, error) -> Void in
                guard let data = data else { return }
                
                dispatch_async(dispatch_get_main_queue(), { [weak self] () -> Void in
                    guard let weakSelf = self else { return }
                    
                    let image = UIImage(data: data)
                    icons[indexPath.row] = image
                    weakSelf.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .None)
                })
            }
            task.resume()
        }
        
        return cell
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
        icons = [UIImage?]()
        while icons.count < json?.count
        {
            icons.append(nil)
        }
        
        tableView.reloadData()
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

        let service = DetailViewController.DataModelService(title: title, description: description)
        detailVC.dataService = service
    }
}

