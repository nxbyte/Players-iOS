//  Warren Seto
//  SearchView.swift
//  Players App for Youtube

import UIKit

final class SearchView: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UITextFieldDelegate, UIGestureRecognizerDelegate
{
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var searchField: UITextField!
    let spinner = UIActivityIndicatorView(activityIndicatorStyle: .WhiteLarge)
    
    var videoArray:[Video] = [], getMoreFlag = true, query:String?
    
    override func viewDidLoad()
    {
        super.viewDidLoad()

        searchField.delegate = self
        
        spinner.color = UIColor.grayColor()
        view.addSubview(spinner)
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(SearchView.longPress(_:)))
        longPress.minimumPressDuration = 0.5
        longPress.delegate = self
        collectionView.addGestureRecognizer(longPress)
        
        collectionView.delaysContentTouches = false
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool
    {
        textField.resignFirstResponder()
        
        if (textField.text == "")
        {
            videoArray = []
            collectionView.reloadData()
            return false
        }
        
        else if (textField.text == query)
        {
            return false
        }
        
        videoArray = []
        collectionView.reloadData()
        spinner.center = CGPoint(x: view.frame.width/2, y: view.frame.height/4)
        spinner.startAnimating()
        
        Server.search(textField.text!, videoArray.count)
        {
            (videos) -> () in
            
            self.videoArray = videos
            
            dispatch_async(dispatch_get_main_queue())
            {
                self.spinner.stopAnimating()
                
                if (self.videoArray.isEmpty) { showLabel("No Results", viewController: self) }
                else { self.collectionView.reloadSections(NSIndexSet(index: 0)) }
            }
        }
        
        query = textField.text
        getMoreFlag = true
        
        return true
    }
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView)
    {
        if (getMoreFlag) // Limited to 50 because of server cannot get more than 50 videos per page... 'videoArray.count == 25'
        {
            getMoreFlag = false
            
            if (scrollView.contentOffset.y + scrollView.frame.size.height >= scrollView.contentSize.height)
            {
                Server.search(query!, videoArray.count)
                {
                    (videos) -> () in
                
                    self.videoArray += videos
                
                    dispatch_async(dispatch_get_main_queue())
                    {
                        self.collectionView.reloadSections(NSIndexSet(index: 0))
                    }
                }
            }
        }
    }
    
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