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
}
