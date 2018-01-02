/*
 Developer : Warren Seto
 Classes   : CacheVC
 Project   : Players App (v2)
 */

import UIKit
import AVKit
import CoreData

final class CacheVC: UICollectionViewController, UICollectionViewDelegateFlowLayout, NSFetchedResultsControllerDelegate, URLSessionDownloadDelegate {
    
    
    // MARK: Properties
    
    private let AppController : AppDelegate = UIApplication.shared.delegate as! AppDelegate
    
    private lazy var coreData: NSFetchedResultsController<VideoCache> = {
        let fetch:NSFetchRequest<VideoCache> = VideoCache.fetchRequest()
        fetch.sortDescriptors = [NSSortDescriptor(key: "downloaded", ascending: false)]
        fetch.fetchBatchSize = 10
        
        return NSFetchedResultsController(fetchRequest: fetch, managedObjectContext: AppController.persistentContainer.viewContext, sectionNameKeyPath: nil, cacheName: nil)
    }()
    
    private let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!.path
    
    private lazy var downloadProgress:[String:String] = [:]
    
    private var refreshTimer:Timer!
    
    
    // MARK: UIViewController Implementation
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        coreData.delegate = self
        try? self.coreData.performFetch()

        startTimer()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if !refreshTimer.isValid {
            startTimer()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        refreshTimer.invalidate()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate(alongsideTransition: { (context) in
            if self.coreData.sections?.count != 0 {
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
        let selectedResult = self.coreData.object(at: selectedIndexPath)
        
        present({ [unowned self] in
            
            $0.addAction(UIAlertAction(title: "Save to Photos", style: .default) { alert in
                
                let path = "\(self.DocumentsDirectory)/\(selectedResult.id!).mp4"
                
                if (FileManager.default.fileExists(atPath: path) && UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(path)) {
                    UISaveVideoAtPathToSavedPhotosAlbum(path, nil, nil, nil)
                }
            })
            
            $0.addAction(UIAlertAction(title: "Delete Video", style: .default) { alert in
                self.AppController.removeCacheVideo(ID: selectedResult.id!)
            })
            
            $0.addAction(UIAlertAction(title: "Share Video", style: .default) { alert in
                
                self.present({
                    $0.popoverPresentationController?.sourceView = self.collectionView
                    $0.popoverPresentationController?.sourceRect = CGRect(x: tapPoint.x, y: tapPoint.y, width: 1.0, height: 1.0)
                    
                    return $0
                } (UIActivityViewController(activityItems: ["Take a look:\n", selectedResult.name! + "\n", URL(string:"https://youtu.be/\(selectedResult.id!)")!], applicationActivities: nil)), animated: true, completion: nil)
            })
            
            $0.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            
            $0.popoverPresentationController?.sourceView = self.collectionView
            $0.popoverPresentationController?.sourceRect = CGRect(x: tapPoint.x, y: tapPoint.y, width: 1.0, height: 1.0)
            return $0
            } (UIAlertController(title: "Options", message: nil, preferredStyle: .actionSheet)), animated: true, completion: {
                self.collectionView?.cellForItem(at: selectedIndexPath)?.isHighlighted = false
        })
    }
    
    
    // MARK: NSFetchedResultsControllerDelegate Implementation
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        switch type {
        case .delete:
            collectionView?.deleteItems(at: [indexPath!])
            
        case .insert:
            collectionView?.insertItems(at: [newIndexPath!])
            
        default:
            collectionView?.reloadItems(at: [indexPath!])
        }
    }

    
    // URLSessionDownloadDelegate Implementation
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
        try? FileManager().moveItem(at: location, to: DocumentsDirectory.appendingPathComponent("\(downloadTask.taskDescription!).mp4"))
    }
    
    
    // CacheVC Functions
    
    private func startTimer() {
        
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { (timer) in
            self.AppController.downloadsSession.getAllTasks { (tasks) in
                var currentProgress:[String:String] = [:]
                
                if tasks.isEmpty {
                    timer.invalidate()
                } else {
                    for task in tasks {
                        currentProgress[task.taskDescription!] = "Downloading... \(Int((task.progress.fractionCompleted * 100).rounded()))%"
                    }
                }
                
                DispatchQueue.main.async {
                    self.downloadProgress = currentProgress
                    UIView.performWithoutAnimation {
                        self.collectionView?.reloadSections(IndexSet(integer: 0))
                    }
                }
            }
        }
        
        refreshTimer.tolerance = 5.0
    }
    
    
    // MARK: UICollectionViewDataSource Implementation

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return coreData.sections!.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if let sections = coreData.sections {
            let sectionInfo = sections[section]
            return sectionInfo.numberOfObjects
        }
        
        return 0
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if UIDevice.current.userInterfaceIdiom == .pad {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "LargeVideoCell", for: indexPath) as! LargeVideoCell
            
            cell.thumbnail.image = UIImage(contentsOfFile: "\(DocumentsDirectory)/\(coreData.object(at: indexPath).id!).jpg") ?? #imageLiteral(resourceName: "Placeholder_Icon")
            cell.title.text = coreData.object(at: indexPath).name
            cell.subtitle.text = "\(downloadProgress[coreData.object(at: indexPath).id!] ?? "")"
            cell.duration.text = coreData.object(at: indexPath).duration
            
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CompactVideoCell", for: indexPath) as! CompactVideoCell
            
            cell.thumbnail.image = UIImage(contentsOfFile: "\(DocumentsDirectory)/\(coreData.object(at: indexPath).id!).jpg") ?? #imageLiteral(resourceName: "Placeholder_Icon")
            cell.title.text = coreData.object(at: indexPath).name
            cell.views.text = coreData.object(at: indexPath).channelname
            cell.duration.text = coreData.object(at: indexPath).duration
            cell.channelName.text = downloadProgress[coreData.object(at: indexPath).id!]
            
            return cell
        }
    }
    
    
    // MARK: UICollectionViewDelegate Implementation
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let path = "\(DocumentsDirectory)/\(coreData.object(at: indexPath).id!).mp4"

        if (FileManager.default.fileExists(atPath: path)) {
            
            let videoPlayer:AVPlayerViewController = {
                $0.view.sizeToFit()
                $0.showsPlaybackControls = true
                $0.player = AVPlayer(url: URL(fileURLWithPath: path))
                return $0
            } (AVPlayerViewController())

            self.present(videoPlayer, animated: true, completion: {
                videoPlayer.player!.play()
            })
        }
    }
    
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
    
    internal func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return UIDevice.current.userInterfaceIdiom == .phone ?
            CGSize(width: UIScreen.main.bounds.width - 10, height: 100) :
            CGSize(width: 320, height: 235)
    }
    
    internal func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIDevice.current.userInterfaceIdiom == .phone ? UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0) : UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
    }
}
