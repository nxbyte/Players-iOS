//  Warren Seto
//  CacheView.swift
//  Players App for Youtube

import UIKit

final class CacheView: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UIGestureRecognizerDelegate
{
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var downloadingProgress: UIActivityIndicatorView!
    
    var videoArray:[Video] = []
    
    var isDownloading = NSTimer()
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(CacheView.longPress(_:)))
        longPress.minimumPressDuration = 0.5
        longPress.delegate = self
        collectionView.addGestureRecognizer(longPress)
        
        collectionView.delaysContentTouches = false
    }
    
    override func viewWillAppear(animated: Bool)
    {
        if (videoArray.count != LocalStore.count("cache")) { loadCache() }
    }
    
    //----------------------------------------------------------------------
    
    // Insert Download Code Here...
    
    //----------------------------------------------------------------------
    
    func loadCache()
    {
        var newArray:[Video] = []
        var temp:[String]
        
        for element in LocalStore.values("cache")
        {
            temp = element.componentsSeparatedByString("///:///")
    
            newArray.append(Video(title:temp[0], thumbnail:"\(temp[1]).jpg", time: "", views:temp[2], url: "\(temp[1]).mp4", channelName:temp[3], channelID:temp[1]))
        }
        
        videoArray = newArray
        collectionView.reloadData()
    }

    func longPress(gesture:UILongPressGestureRecognizer)
    {
        if (gesture.state != UIGestureRecognizerState.Began) { return }
        
        let tapPoint = gesture.locationInView(collectionView)
        
        if (collectionView.indexPathForItemAtPoint(tapPoint) == nil) { return }
        
        let popup = UIAlertController(title: "Options", message: "", preferredStyle: UIAlertControllerStyle.ActionSheet)
        
        popup.addAction(UIAlertAction(title: "Save to Photos", style: UIAlertActionStyle.Default)
        {
            alert in
                
            let cell = self.videoArray[self.collectionView.indexPathForItemAtPoint(tapPoint)!.row].url
            
            UISaveVideoAtPathToSavedPhotosAlbum(FileSystem.getPath(.DocumentDirectory, fileName: cell), nil, nil, nil)
        })
        
        popup.addAction(UIAlertAction(title: "Delete", style: UIAlertActionStyle.Destructive)
        {
            alert in
            
            let index = self.collectionView.indexPathForItemAtPoint(tapPoint)!.row
            
            FileSystem.deleteFile(.DocumentDirectory, fileName: self.videoArray[index].url)
            FileSystem.deleteFile(.DocumentDirectory, fileName: self.videoArray[index].thumbnail)
            
            LocalStore.remove("cache", dictKey: self.videoArray[index].channelID)
            
            self.videoArray.removeAtIndex(index)
            self.collectionView.reloadData()
        })
        
        popup.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
        
        popup.popoverPresentationController?.sourceView = collectionView
        popup.popoverPresentationController?.sourceRect = CGRectMake(tapPoint.x, tapPoint.y, 1.0, 1.0)
        presentViewController(popup, animated: true, completion: nil)
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath)
    {
        let path = FileSystem.getPath(.DocumentDirectory, fileName: videoArray[indexPath.row].url)!
        
        if (FileSystem.fileExist(path.path!))
        {
            presentViewController(VideoView(URL: path), animated: true, completion: nil)
        }
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell
    {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("cell", forIndexPath: indexPath) as! UICard
        
        if let thumbData = FileSystem.getFile(.DocumentDirectory, fileName: videoArray[indexPath.row].thumbnail)
        {
            cell.image.image = UIImage(data: thumbData)
        }
        
        cell.name.text = videoArray[indexPath.row].title
        cell.account.text = videoArray[indexPath.row].channelName
        cell.time.text = videoArray[indexPath.row].views
        cell.time.backgroundColor = cell.time.backgroundColor!.colorWithAlphaComponent(0.5)
        cell.views.text = "100 MB"
        
        cell.contentView.frame = cell.bounds
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didHighlightItemAtIndexPath indexPath: NSIndexPath)
    {
        (collectionView.cellForItemAtIndexPath(indexPath) as! UICard).backgroundColor = UIColor(red: 0.82, green: 0.82, blue: 0.82, alpha: 1)
    }
    
    func collectionView(collectionView: UICollectionView, didUnhighlightItemAtIndexPath indexPath: NSIndexPath)
    {
        (collectionView.cellForItemAtIndexPath(indexPath) as! UICard).backgroundColor = UIColor.whiteColor()
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize
    {
        //Default iPad Dimensions
        var size = CGSizeMake(310, 90)
        
        //Change to iPhone Dimensions
        if (UIDevice.currentDevice().userInterfaceIdiom == UIUserInterfaceIdiom.Phone)
        {
            //height = CGFloat(90)
            size.width = (UIScreen.mainScreen().bounds.width - 10)
        }
        
        return size
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int { return videoArray.count }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator)
    {
        coordinator.animateAlongsideTransition(
            {
                context -> Void in
                
                if self.videoArray.count != 0
                {
                    self.collectionView.performBatchUpdates(nil, completion: nil)
                }
                
            }, completion: nil)
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle { return UIStatusBarStyle.LightContent }
    
    override func didReceiveMemoryWarning() { super.didReceiveMemoryWarning() }
}
