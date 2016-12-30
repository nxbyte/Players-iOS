//  Warren Seto
//  ChannelView.swift
//  Players App for Youtube

import UIKit

final class ChannelView: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UIGestureRecognizerDelegate
{
    var channelArray:[Channel] = []
    @IBOutlet weak var collectionView: UICollectionView!

    let cache:NSCache<NSString, UIImage> = NSCache()
    
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
            
            if (FileSystem.getFile(FileManager.SearchPathDirectory.libraryDirectory, fileName: "\(id).jpg") == nil)
            {
                Server.channelData("\(id)",
                    {
                        (channelName, thumbnailURL) -> () in
                        
                        Just.get(thumbnailURL)
                            {
                                (r) in
                                
                                if (r.ok)
                                {
                                    try? r.content?.write(to: URL(fileURLWithPath: "\(NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.libraryDirectory, .userDomainMask, true).first!)/\(id).jpg"), options: [.atomic])
                                }
                        }
                })
            }
        }
    }
    
    @IBAction func closeButton(_ sender: AnyObject)
    {
        dismiss(animated: true, completion: nil)
    }
    
    func longPress(_ gesture:UILongPressGestureRecognizer)
    {
        if (gesture.state != UIGestureRecognizerState.began) { return }
        
        let tapPoint = gesture.location(in: collectionView)
        
        if (collectionView.indexPathForItem(at: tapPoint) == nil) { return }
        
        let popup = UIAlertController(title: "Options for \(self.channelArray[self.collectionView.indexPathForItem(at: tapPoint)!.row].name)", message: "", preferredStyle: UIAlertControllerStyle.actionSheet)
        
        popup.addAction(UIAlertAction(title: "Unsubscribe", style: UIAlertActionStyle.destructive)
            {
                alert in
                
                let cell = self.channelArray[self.collectionView.indexPathForItem(at: tapPoint)!.row].ID
                
                self.channelArray.remove(at: self.collectionView.indexPathForItem(at: tapPoint)!.row)
                self.collectionView.reloadSections(IndexSet(integer: 0))
                
                FileSystem.deleteFile(.libraryDirectory, fileName: "\(cell).jpg")
                LocalStore.remove("subs", dictKey: cell)
            })
        
        popup.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil))
        
        popup.popoverPresentationController?.sourceView = collectionView
        popup.popoverPresentationController?.sourceRect = CGRect(x: tapPoint.x, y: tapPoint.y, width: 1.0, height: 1.0)
        present(popup, animated: true, completion: nil)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath)
    {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "loadChannel"), object: nil, userInfo: ["ID": channelArray[indexPath.row].ID])
        
        dismiss(animated: true, completion: nil)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! ChannelPanel

        if let imageCache = cache.object(forKey: "\(channelArray[indexPath.row].ID).jpg" as NSString)
        {
            cell.image.image = imageCache
        }
            
        else if (FileSystem.fileExist(FileSystem.getPath(FileManager.SearchPathDirectory.libraryDirectory, fileName: "\(self.channelArray[indexPath.row].ID).jpg")))
        {
            DispatchQueue.global(qos: DispatchQoS.QoSClass.userInitiated).async
            {
                let num = indexPath

                let image = UIImage(data: FileSystem.getFile(FileManager.SearchPathDirectory.libraryDirectory, fileName: "\(self.channelArray[indexPath.row].ID).jpg")!)
                self.cache.setObject(image!, forKey: "\(self.channelArray[indexPath.row].ID).jpg" as NSString)
                    
                DispatchQueue.main.async
                {
                    (collectionView.cellForItem(at: num) as! ChannelPanel).image.image = image
                }
            }
        }
        
        cell.image.layer.masksToBounds = true
        cell.image.layer.cornerRadius = 2.0
        
        cell.name.text = channelArray[indexPath.row].name
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int { return channelArray.count }
    
    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath)
    {
        (collectionView.cellForItem(at: indexPath) as! ChannelPanel).image.alpha = 0.7
    }
    
    func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath)
    {
        (collectionView.cellForItem(at: indexPath) as! ChannelPanel).image.alpha = 1
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle { return UIStatusBarStyle.lightContent }
    
    override func didReceiveMemoryWarning() { super.didReceiveMemoryWarning() }
}

struct Channel
{
    var name:String
    var ID:String
}
