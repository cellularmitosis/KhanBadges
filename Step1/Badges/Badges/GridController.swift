//
//  GridController.swift
//  Badges
//
//  Created by Pepas Personal on 2/11/16.
//  Copyright © 2016 Pepas Labs. All rights reserved.
//

import UIKit

class GridCell: UICollectionViewCell
{
    @IBOutlet weak var imageView: UIImageView!
}

class GridController: UICollectionViewController
{
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("GridCell", forIndexPath: indexPath) as! GridCell
        
        let imageName = String(format: "Image-%i", indexPath.row % 19)
        cell.imageView?.image = UIImage(named: imageName)!
        
        return cell
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 246
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let cell = sender as! GridCell
        let detailVC = segue.destinationViewController as! DetailViewController
        let _ = detailVC.view
        
        detailVC.imageView.image = cell.imageView?.image
        
        let indexPath = self.collectionView!.indexPathForCell(cell)!
        detailVC.titleLabel.text = titles[indexPath.row % titles.count]
        detailVC.descriptionLabel.text = descriptions[indexPath.row % descriptions.count]
    }
}
