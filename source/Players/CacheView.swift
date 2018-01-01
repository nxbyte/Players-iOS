//  Warren Seto
//  CacheView.swift
//  Players App for Youtube

import UIKit

final class CacheView: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UIGestureRecognizerDelegate
{
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var downloadingProgress: UIActivityIndicatorView!
    
    var videoArray:[Video] = []
    
    var isDownloading = Timer()
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(CacheView.longPress(_:)))
        longPress.minimumPressDuration = 0.5
        longPress.delegate = self
        collectionView.addGestureRecognizer(longPress)
        
        collectionView.delaysContentTouches = false
    }
    
    override func viewWillAppear(_ animated: Bool)
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
            temp = element.components(separatedBy: "///:///")
    
            newArray.append(Video(title:temp[0], thumbnail:"\(temp[1]).jpg", time: "", views:temp[2], url: "\(temp[1]).mp4", channelName:temp[3], channelID:temp[1]))
        }
        
        videoArray = newArray
        collectionView.reloadData()
    }

    @objc func longPress(_ gesture:UILongPressGestureRecognizer)
    {
        if (gesture.state != UIGestureRecognizerState.began) { return }
        
        let tapPoint = gesture.location(in: collectionView)
        
        if (collectionView.indexPathForItem(at: tapPoint) == nil) { return }
        
        let popup = UIAlertController(title: "Options", message: "", preferredStyle: UIAlertControllerStyle.actionSheet)
        
        popup.addAction(UIAlertAction(title: "Save to Photos", style: UIAlertActionStyle.default)
        {
            alert in
                
            let cell = self.videoArray[self.collectionView.indexPathForItem(at: tapPoint)!.row].url
            
            UISaveVideoAtPathToSavedPhotosAlbum(FileSystem.getPath(.documentDirectory, fileName: cell), nil, nil, nil)
        })
        
        popup.addAction(UIAlertAction(title: "Delete", style: UIAlertActionStyle.destructive)
        {
            alert in
            
            let index = self.collectionView.indexPathForItem(at: tapPoint)!.row
            
            FileSystem.deleteFile(.documentDirectory, fileName: self.videoArray[index].url)
            FileSystem.deleteFile(.documentDirectory, fileName: self.videoArray[index].thumbnail)
            
            LocalStore.remove("cache", dictKey: self.videoArray[index].channelID)
            
            self.videoArray.remove(at: index)
            self.collectionView.reloadData()
        })
        
        popup.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil))
        
        popup.popoverPresentationController?.sourceView = collectionView
        popup.popoverPresentationController?.sourceRect = CGRect(x: tapPoint.x, y: tapPoint.y, width: 1.0, height: 1.0)
        present(popup, animated: true, completion: nil)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath)
    {
        let path = FileSystem.getPath(.documentDirectory, fileName: videoArray[indexPath.row].url)!
        
        if (FileSystem.fileExist(path.path))
        {
            present(VideoView(URL: path), animated: true, completion: nil)
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! UICard
        
        if let thumbData = FileSystem.getFile(.documentDirectory, fileName: videoArray[indexPath.row].thumbnail)
        {
            cell.image.image = UIImage(data: thumbData)
        }
        
        cell.name.text = videoArray[indexPath.row].title
        cell.account.text = videoArray[indexPath.row].channelName
        cell.time.text = videoArray[indexPath.row].views
        cell.time.backgroundColor = cell.time.backgroundColor!.withAlphaComponent(0.5)
        cell.views.text = "100 MB"
        
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
