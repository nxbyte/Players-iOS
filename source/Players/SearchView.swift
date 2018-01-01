//  Warren Seto
//  SearchView.swift
//  Players App for Youtube

import UIKit

final class SearchView: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UIScrollViewDelegate, UITextFieldDelegate, UIGestureRecognizerDelegate
{
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var searchField: UITextField!
    let spinner = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
    
    var videoArray:[Video] = [], getMoreFlag = true, query:String?
    
    override func viewDidLoad()
    {
        super.viewDidLoad()

        searchField.delegate = self
        
        spinner.color = UIColor.gray
        view.addSubview(spinner)
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(SearchView.longPress(_:)))
        longPress.minimumPressDuration = 0.5
        longPress.delegate = self
        collectionView.addGestureRecognizer(longPress)
        
        collectionView.delaysContentTouches = false
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool
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
            
            DispatchQueue.main.async
            {
                self.spinner.stopAnimating()
                
                if (self.videoArray.isEmpty) { showLabel("No Results", viewController: self) }
                else { self.collectionView.reloadSections(IndexSet(integer: 0)) }
            }
        }
        
        query = textField.text
        getMoreFlag = true
        
        return true
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView)
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
                
                    DispatchQueue.main.async
                    {
                        self.collectionView.reloadSections(IndexSet(integer: 0))
                    }
                }
            }
        }
    }
    
    func downloadVideo(_ video:Video, quaility:Int)
    {
        Server.videoURL(video.url, quaility)
            {
                (mp4Url) -> () in
                
                if (mp4Url != "")
                {
                    let videoID = Server.videoID(video.url)
                    
                    URLSession.shared.dataTask(with: URL(string: video.thumbnail)!, completionHandler: { (data, res, err) in
                        if data != nil {
                            try? data!.write(to: URL(fileURLWithPath: "\(NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, .userDomainMask, true).first!)/\(videoID).jpg"), options: [.atomic])
                        }
                    })
                    
                    LocalStore.set("cache", dictKey: videoID, dictValue: "\(video.title)///:///\(videoID)///:///\(video.time)///:///\(video.channelName)")
                    
                    URLSession.shared.dataTask(with: URL(string: mp4Url)!, completionHandler: { (data, res, err) in
                        
                        if data != nil {
                            try? data!.write(to: URL(fileURLWithPath: "\(NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, .userDomainMask, true).first!)/\(videoID).mp4"), options: [.atomic])
                        }
                    })
                }
        }
    }
    
    @objc func longPress(_ gesture:UILongPressGestureRecognizer)
    {
        if (gesture.state != UIGestureRecognizerState.began) { return }
        
        let tapPoint = gesture.location(in: collectionView)
        
        if (collectionView.indexPathForItem(at: tapPoint) == nil) { return }
        
        let cachePopup = UIAlertController(title: "Options", message: "", preferredStyle: UIAlertControllerStyle.actionSheet)
        
        cachePopup.addAction(UIAlertAction(title: "Download SD", style: UIAlertActionStyle.default)
            {
                alert in
                self.downloadVideo(self.videoArray[self.collectionView.indexPathForItem(at: tapPoint)!.row], quaility: 360)
            })
        
        cachePopup.addAction(UIAlertAction(title: "Download HD", style: UIAlertActionStyle.default)
            {
                alert in
                self.downloadVideo(self.videoArray[self.collectionView.indexPathForItem(at: tapPoint)!.row], quaility: 720)
            })
        
        cachePopup.addAction(UIAlertAction(title: "Share Video", style: UIAlertActionStyle.default)
            {
                alert in
                
                let videoInfo = self.videoArray[self.collectionView.indexPathForItem(at: tapPoint)!.row]
                
                let shareSheet = UIActivityViewController(activityItems: ["Take a look:\n", videoInfo.title + "\n", URL(string:"https://youtu.be/\(Server.videoID(videoInfo.url))")!], applicationActivities: nil)
                
                shareSheet.popoverPresentationController?.sourceView = self.collectionView
                shareSheet.popoverPresentationController?.sourceRect = CGRect(x: tapPoint.x, y: tapPoint.y, width: 1.0, height: 1.0)
                
                self.navigationController?.present(shareSheet, animated: true, completion: nil)
            })
        
        cachePopup.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil))
        
        cachePopup.popoverPresentationController?.sourceView = collectionView
        cachePopup.popoverPresentationController?.sourceRect = CGRect(x: tapPoint.x, y: tapPoint.y, width: 1.0, height: 1.0)
        present(cachePopup, animated: true, completion: nil)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath)
    {
        Server.videoURL(videoArray[indexPath.row].url, 360)
            {
                (videoURL) -> () in
                
                if (!videoURL.isEmpty)
                {
                    DispatchQueue.main.async
                        {
                            self.present(VideoView(url: videoURL), animated: true, completion: nil)
                    }
                }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! UICard
        
        Network.GET(videoArray[indexPath.row].thumbnail)
        {
            (code, data) in
            
            if data != nil
            {
                DispatchQueue.main.async
                {
                    cell.image.image = UIImage(data: data!)
                }
            }
        }
        
        cell.name.text = videoArray[indexPath.row].title
        cell.time.text = videoArray[indexPath.row].time
        cell.time.backgroundColor = cell.time.backgroundColor!.withAlphaComponent(0.5)
        cell.account.text = videoArray[indexPath.row].channelName
        cell.views.text = videoArray[indexPath.row].views
        
        cell.contentView.frame = cell.bounds
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath)
    {
        (collectionView.cellForItem(at: indexPath) as! UICard).backgroundColor = UIColor(red: 0.82, green: 0.82, blue: 0.82, alpha: 1)
    }
    
    func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath)
    {
        (collectionView.cellForItem(at: indexPath) as! UICard).backgroundColor = UIColor.white
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: IndexPath) -> CGSize
    {
        //Default iPad Dimensions
        var size = CGSize(width: 310, height: 90)
        
        //Change to iPhone Dimensions
        if (UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.phone)
        {
            //height = CGFloat(90)
            size.width = (UIScreen.main.bounds.width - 10)
        }
        
        return size
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int { return videoArray.count }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator)
    {
        coordinator.animate(
            alongsideTransition: {
                context -> Void in
                
                if self.videoArray.count != 0
                {
                    self.collectionView.performBatchUpdates(nil, completion: nil)
                }
                
            }, completion: nil)
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle { return UIStatusBarStyle.lightContent }
    
    override func didReceiveMemoryWarning() { super.didReceiveMemoryWarning() }
}
