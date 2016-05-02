//  Warren Seto
//  SubscriptionView.swift
//  Players App for Youtube

import UIKit

final class SubscriptionView: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UIGestureRecognizerDelegate
{
    @IBOutlet weak var collectionView: UICollectionView!
    let refresh = UIRefreshControl()
    
    var videoArray:[Video] = [], allSubs:[String] = []
    
    override func viewDidLoad()
    {
        super.viewDidLoad()

        reloadSubs()
        
        collectionView.addSubview(refresh)
        refresh.beginRefreshing()
        refresh.addTarget(self, action: #selector(SubscriptionView.reloadSubs), forControlEvents: UIControlEvents.ValueChanged)
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(SubscriptionView.longPress(_:)))
        longPress.minimumPressDuration = 0.5
        longPress.delegate = self
        collectionView.addGestureRecognizer(longPress)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(SubscriptionView.loadChannel(_:)), name: "loadChannel", object: nil)
        
        collectionView.delaysContentTouches = false
    }

    func reloadSubs()
    {
        allSubs = LocalStore.keys("subs")
        
        Server.subs(allSubs,
        {
            (videos) -> () in
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0))
            {
                self.videoArray = videos
                    
                dispatch_async(dispatch_get_main_queue())
                {
                    self.refresh.endRefreshing()
                    self.collectionView.reloadSections(NSIndexSet(index: 0))
                            
                    if (self.videoArray.isEmpty)
                    {
                        showLabel("No Videos", viewController: self)
                    }
                }
            }
        })
    }
    
    func loadChannel(notify: NSNotification)
    {
        videoArray = []
        collectionView.reloadData()
        refresh.beginRefreshing()
        
        Server.sub(notify.userInfo!["ID"] as! String, 
        {
            (videos) -> () in
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0))
                {
                    self.videoArray = videos
                    
                    dispatch_async(dispatch_get_main_queue())
                        {
                            self.refresh.endRefreshing()
                            self.collectionView.reloadSections(NSIndexSet(index: 0))
                    }
            }
        })
        
    }
    
    //Share-able code
    func downloadVideo(video:Video, quaility:Int)
    {
        Server.videoURL(video.url, quaility)
            {
                (mp4Url) -> () in
                
                if (mp4Url != "")
                {
                    let videoID = Server.videoID(video.url)

                    Just.get(video.thumbnail)
                    {
                        (r) in
                            
                        if (r.ok)
                        {
                            r.content?.writeToFile("\(NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, .UserDomainMask, true).first!)/\(videoID).jpg", atomically: true)
                        }
                    }
                    
                    LocalStore.set("cache", dictKey: videoID, dictValue: "\(video.title)///:///\(videoID)///:///\(video.time)///:///\(video.channelName)")
                    
                    Just.get(mp4Url)
                        {
                            (r) in
                            
                            if (r.ok)
                            {
                                r.content?.writeToFile("\(NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, .UserDomainMask, true).first!)/\(videoID).mp4", atomically: true)
                            }
                    }
                }
        }
    }
    
    //Share-able code
    func longPress(gesture:UILongPressGestureRecognizer)
    {
        if (gesture.state != UIGestureRecognizerState.Began) { return }
        
        let tapPoint = gesture.locationInView(collectionView)
        
        if (collectionView.indexPathForItemAtPoint(tapPoint) == nil) { return }
        
        let cachePopup = UIAlertController(title: "Options", message: "", preferredStyle: UIAlertControllerStyle.ActionSheet)
        
        cachePopup.addAction(UIAlertAction(title: "Download SD", style: UIAlertActionStyle.Default)
            {
                alert in
                self.downloadVideo(self.videoArray[self.collectionView.indexPathForItemAtPoint(tapPoint)!.row], quaility: 360)
            })
        
        cachePopup.addAction(UIAlertAction(title: "Download HD", style: UIAlertActionStyle.Default)
            {
                alert in
                self.downloadVideo(self.videoArray[self.collectionView.indexPathForItemAtPoint(tapPoint)!.row], quaility: 720)
            })
        
        cachePopup.addAction(UIAlertAction(title: "Share Video", style: UIAlertActionStyle.Default)
            {
                alert in
                
                let videoInfo = self.videoArray[self.collectionView.indexPathForItemAtPoint(tapPoint)!.row]
                
                let shareSheet = UIActivityViewController(activityItems: ["Take a look:\n", videoInfo.title + "\n", NSURL(string:"https://youtu.be/\(Server.videoID(videoInfo.url))")!], applicationActivities: nil)
                
                shareSheet.popoverPresentationController?.sourceView = self.collectionView
                shareSheet.popoverPresentationController?.sourceRect = CGRect(x: tapPoint.x, y: tapPoint.y, width: 1.0, height: 1.0)
                
                self.navigationController?.presentViewController(shareSheet, animated: true, completion: nil)
            })
        
        cachePopup.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
        
        cachePopup.popoverPresentationController?.sourceView = collectionView
        cachePopup.popoverPresentationController?.sourceRect = CGRect(x: tapPoint.x, y: tapPoint.y, width: 1.0, height: 1.0)
        presentViewController(cachePopup, animated: true, completion: nil)
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath)
    {
        Server.videoURL(videoArray[indexPath.row].url, 360)
        {
            (videoURL) -> () in
            
            if (!videoURL.isEmpty)
            {
                dispatch_async(dispatch_get_main_queue())
                {
                    self.presentViewController(VideoView(url: videoURL), animated: true, completion: nil)
                }
            }
        }
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell
    {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("cell", forIndexPath: indexPath) as! UICard
        
        NSURLSession.sharedSession().dataTaskWithURL(NSURL(string: videoArray[indexPath.row].thumbnail)!)
            {
                (data, res, err) -> Void in

                dispatch_async(dispatch_get_main_queue())
                    {
                        cell.image.image = UIImage(data: data!)
                }
                
            }.resume()

        cell.name.text = videoArray[indexPath.row].title
        cell.time.text = videoArray[indexPath.row].time
        cell.time.backgroundColor = cell.time.backgroundColor!.colorWithAlphaComponent(0.5)
        cell.account.text = videoArray[indexPath.row].channelName
        cell.views.text = videoArray[indexPath.row].views
        
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
        coordinator.animateAlongsideTransition ( //add guard here
            {
                (a) -> Void in
                
                if (self.videoArray.count != 0)
                {
                    self.collectionView.performBatchUpdates(nil, completion: nil)
                }
                
            }, completion: nil)
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle { return UIStatusBarStyle.LightContent }
    
    override func didReceiveMemoryWarning() { super.didReceiveMemoryWarning() }
}

