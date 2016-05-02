//  Warren Seto
//  ChannelView.swift
//  Players App for Youtube

import UIKit

final class ChannelView: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UIGestureRecognizerDelegate
{
    var channelArray:[Channel] = []
    @IBOutlet weak var collectionView: UICollectionView!

    let cache:NSCache = NSCache()
    
    override func viewDidLoad()
    {
        loadSubs()
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(ChannelView.longPress(_:)))
        longPress.minimumPressDuration = 0.7
        longPress.delegate = self
        collectionView.addGestureRecognizer(longPress)
        
        cache.countLimit = 20
        
        collectionView.delaysContentTouches = false
    }

    func loadSubs()
    {
        for (id, name) in LocalStore.getDictionary("subs")
        {
            channelArray.append(Channel(name: "\(name)", ID: "\(id)"))
            
            if (FileSystem.getFile(NSSearchPathDirectory.LibraryDirectory, fileName: "\(id).jpg") == nil)
            {
                Server.channelData("\(id)",
                    {
                        (channelName, thumbnailURL) -> () in
                        
                        Just.get(thumbnailURL)
                            {
                                (r) in
                                
                                if (r.ok)
                                {
                                    r.content?.writeToFile("\(NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.LibraryDirectory, .UserDomainMask, true).first!)/\(id).jpg", atomically: true)
                                }
                        }
                })
            }
        }
    }
    
    @IBAction func closeButton(sender: AnyObject)
    {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func longPress(gesture:UILongPressGestureRecognizer)
    {
        if (gesture.state != UIGestureRecognizerState.Began) { return }
        
        let tapPoint = gesture.locationInView(collectionView)
        
        if (collectionView.indexPathForItemAtPoint(tapPoint) == nil) { return }
        
        let popup = UIAlertController(title: "Options for \(self.channelArray[self.collectionView.indexPathForItemAtPoint(tapPoint)!.row].name)", message: "", preferredStyle: UIAlertControllerStyle.ActionSheet)
        
        popup.addAction(UIAlertAction(title: "Unsubscribe", style: UIAlertActionStyle.Destructive)
            {
                alert in
                
                let cell = self.channelArray[self.collectionView.indexPathForItemAtPoint(tapPoint)!.row].ID
                
                self.channelArray.removeAtIndex(self.collectionView.indexPathForItemAtPoint(tapPoint)!.row)
                self.collectionView.reloadSections(NSIndexSet(index: 0))
                
                FileSystem.deleteFile(.LibraryDirectory, fileName: "\(cell).jpg")
                LocalStore.remove("subs", dictKey: cell)
            })
        
        popup.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
        
        popup.popoverPresentationController?.sourceView = collectionView
        popup.popoverPresentationController?.sourceRect = CGRectMake(tapPoint.x, tapPoint.y, 1.0, 1.0)
        presentViewController(popup, animated: true, completion: nil)
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath)
    {
        NSNotificationCenter.defaultCenter().postNotificationName("loadChannel", object: nil, userInfo: ["ID": channelArray[indexPath.row].ID])
        
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell
    {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("cell", forIndexPath: indexPath) as! ChannelPanel

        if let imageCache = cache.objectForKey("\(channelArray[indexPath.row].ID).jpg") as? UIImage
        {
            cell.image.image = imageCache
        }
            
        else if (FileSystem.fileExist(FileSystem.getPath(NSSearchPathDirectory.LibraryDirectory, fileName: "\(self.channelArray[indexPath.row].ID).jpg")))
        {
            dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0))
            {
                let num = indexPath

                let image = UIImage(data: FileSystem.getFile(NSSearchPathDirectory.LibraryDirectory, fileName: "\(self.channelArray[indexPath.row].ID).jpg")!)
                self.cache.setObject(image!, forKey: "\(self.channelArray[indexPath.row].ID).jpg")
                    
                dispatch_async(dispatch_get_main_queue())
                {
                    (collectionView.cellForItemAtIndexPath(num) as! ChannelPanel).image.image = image
                }
            }
        }
        
        cell.image.layer.masksToBounds = true
        cell.image.layer.cornerRadius = 2.0
        
        cell.name.text = channelArray[indexPath.row].name
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int { return channelArray.count }
    
    func collectionView(collectionView: UICollectionView, didHighlightItemAtIndexPath indexPath: NSIndexPath)
    {
        (collectionView.cellForItemAtIndexPath(indexPath) as! ChannelPanel).image.alpha = 0.7
    }
    
    func collectionView(collectionView: UICollectionView, didUnhighlightItemAtIndexPath indexPath: NSIndexPath)
    {
        (collectionView.cellForItemAtIndexPath(indexPath) as! ChannelPanel).image.alpha = 1
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle { return UIStatusBarStyle.LightContent }
    
    override func didReceiveMemoryWarning() { super.didReceiveMemoryWarning() }
}

struct Channel
{
    var name:String
    var ID:String
}
