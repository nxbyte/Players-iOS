/*
 Developer : Warren Seto
 Classes   : FeedVC
 Project   : Players App (v2)
 */

import UIKit
import AVFoundation

final class FeedVC: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    // MARK: Properties
    
    private let AppController : AppDelegate = UIApplication.shared.delegate as! AppDelegate
    
    private lazy var videoResults : [VideoResult] = []
    

    // MARK: UIViewController Implementation
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.updateFeed()
        
        self.collectionView?.refreshControl = { [weak self] in
            $0.tintColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
            $0.addTarget(self, action: #selector(FeedVC.updateFeed), for: .valueChanged)
            return $0
        } (UIRefreshControl())

        self.collectionView?.refreshControl?.beginRefreshing()
        self.collectionView?.setContentOffset(CGPoint(x: 0, y: -4), animated: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.setNavigationBarHidden(true, animated: true)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let selected = collectionView?.indexPathsForSelectedItems?.first {
            
            if let videoVC = segue.destination as? VideoPlayerVC {
                
                videoVC.result = videoResults[selected.row]
                
                Cloud.get(video: videoResults[selected.row].videoid, withQuality: "sd", details: { (detail) in

                    DispatchQueue.main.async {
                        videoVC.videoController?.player = AVPlayer(url: detail?.mp4 ?? URL(string: "")!)
                    }
                    
                    videoVC.detail = detail
                })
            }
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate(alongsideTransition: { (context) in
            if !self.videoResults.isEmpty {
                self.collectionView?.performBatchUpdates(nil, completion: nil)
            }
        }, completion: nil)
    }
    
    
    // MARK: IBAction Implementation
    
    @IBAction func longPress(_ sender: UILongPressGestureRecognizer) {

        if (sender.state != UIGestureRecognizerState.began) { return }

        let tapPoint = sender.location(in: collectionView)
        
        if (collectionView?.indexPathForItem(at: tapPoint) == nil) { return }
        
        let selectedIndexPath = self.collectionView!.indexPathForItem(at: tapPoint)!
        let selectedResult = self.videoResults[selectedIndexPath.row]
        
        present({ [unowned self] in

            $0.addAction(UIAlertAction(title: "Download SD", style: .default) { alert in

                if self.AppController.isCachedVideo(ID: selectedResult.videoid) { return }
                
                let cacheImage:UIImage? = UIDevice.current.userInterfaceIdiom == .phone ? (self.collectionView?.cellForItem(at: selectedIndexPath) as! CompactVideoCell).thumbnail.image : (self.collectionView?.cellForItem(at: selectedIndexPath) as! LargeVideoCell).thumbnail.image

                self.AppController.addCacheVideo(result: selectedResult, withQuality: "sd", andCacheImage: cacheImage)
            })
            
            $0.addAction(UIAlertAction(title: "Download HD", style: .default) { alert in
                
                if self.AppController.isCachedVideo(ID: selectedResult.videoid) { return }
                
                let cacheImage:UIImage? = UIDevice.current.userInterfaceIdiom == .phone ? (self.collectionView?.cellForItem(at: selectedIndexPath) as! CompactVideoCell).thumbnail.image : (self.collectionView?.cellForItem(at: selectedIndexPath) as! LargeVideoCell).thumbnail.image
                
                self.AppController.addCacheVideo(result: selectedResult, withQuality: "hd", andCacheImage: cacheImage)
            })
            
            $0.addAction(UIAlertAction(title: "Share Video", style: .default) { alert in
                
                self.present({
                    $0.popoverPresentationController?.sourceView = self.collectionView
                    $0.popoverPresentationController?.sourceRect = CGRect(x: tapPoint.x, y: tapPoint.y, width: 1.0, height: 1.0)
                    return $0
                } (UIActivityViewController(activityItems: ["Take a look:\n", selectedResult.title + "\n", URL(string:"https://youtu.be/\(selectedResult.videoid)")!], applicationActivities: nil)), animated: true, completion: nil)
            })
            
            $0.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            
            $0.popoverPresentationController?.sourceView = self.collectionView
            $0.popoverPresentationController?.sourceRect = CGRect(x: tapPoint.x, y: tapPoint.y, width: 1.0, height: 1.0)
            return $0
        } (UIAlertController(title: "Options", message: nil, preferredStyle: .actionSheet)), animated: true, completion: nil)
    }
    
    
    // MARK: FeedVC Functions
    
    /** Updates the Collection View with the most recent videos for a set of subscribed channels */
    @objc private func updateFeed() {
        
        Cloud.get(subscriptions: AppController.subscriptions) { (results) in
            self.videoResults = results
            
            DispatchQueue.main.async {
                self.collectionView?.refreshControl?.endRefreshing()
                self.collectionView?.reloadSections(IndexSet(integer: 0))
            }
        }
    }
    

    // MARK: UICollectionViewDataSource Implementation
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return videoResults.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "LargeVideoCell", for: indexPath) as! LargeVideoCell
            
            URLSession.shared.dataTask(with: videoResults[indexPath.row].thumbnail, completionHandler: { (data, response, error) in
                if let validData = data {
                    DispatchQueue.main.async {
                        cell.thumbnail.image = UIImage(data: validData)
                    }
                }
            }).resume()
            
            cell.title.text = videoResults[indexPath.row].title
            cell.subtitle.text = "\(videoResults[indexPath.row].channelname) • \(videoResults[indexPath.row].viewcount) views"
            cell.duration.text = videoResults[indexPath.row].duration
            
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CompactVideoCell", for: indexPath) as! CompactVideoCell
            
            URLSession.shared.dataTask(with: videoResults[indexPath.row].thumbnail, completionHandler: { (data, response, error) in
                if let validData = data {
                    DispatchQueue.main.async {
                        cell.thumbnail.image = UIImage(data: validData)
                    }
                }
            }).resume()
            
            cell.title.text = videoResults[indexPath.row].title
            cell.views.text = "\(videoResults[indexPath.row].viewcount) views"
            cell.channelName.text = videoResults[indexPath.row].channelname
            cell.duration.text = videoResults[indexPath.row].duration
            
            return cell
        }
    }
    
    
    // MARK: UICollectionViewDelegate Implementation
    
    override func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        
        if UIDevice.current.userInterfaceIdiom == .phone {
            collectionView.cellForItem(at: indexPath)?.backgroundColor = UIColor(red: 73/255.0, green: 73/255.0, blue: 73/255.0, alpha: 0.3)
        }
            
        else {
            (collectionView.cellForItem(at: indexPath) as! LargeVideoCell).thumbnail.layer.shadowRadius = 1
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        
        if UIDevice.current.userInterfaceIdiom == .phone {
            collectionView.cellForItem(at: indexPath)?.backgroundColor = .clear
        }
            
        else {
            (collectionView.cellForItem(at: indexPath) as! LargeVideoCell).thumbnail.layer.shadowRadius = 6
        }
    }
    
    
    // MARK: UICollectionViewDelegateFlowLayout Implementation
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return UIDevice.current.userInterfaceIdiom == .phone ?
            CGSize(width: UIScreen.main.bounds.width - 10, height: 100) :
            CGSize(width: 320, height: 235)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIDevice.current.userInterfaceIdiom == .phone ? UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0) : UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
    }
}
