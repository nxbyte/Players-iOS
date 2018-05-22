/*
 Developer : Warren Seto
 Classes   : SubscribedVC
 Project   : Players App (v2)
 */

import UIKit
import AVFoundation
import CoreData

final class SubscribedVC: UICollectionViewController, NSFetchedResultsControllerDelegate, VideoProtocol {
    
    
    // MARK: Properties
    
    private lazy var coreData : NSFetchedResultsController<Subscription> = {
        let fetch:NSFetchRequest<Subscription> = Subscription.fetchRequest()
        fetch.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        fetch.fetchBatchSize = 10
        
        return NSFetchedResultsController(fetchRequest: fetch, managedObjectContext: (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext, sectionNameKeyPath: nil, cacheName: nil)
    }()
    
    private let DocumentsDirectory : String = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!.path
    
    
    // MARK: UIViewController Implementation
    
    override func viewDidLoad() {
        super.viewDidLoad()

        coreData.delegate = self
        try? self.coreData.performFetch()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.setNavigationBarHidden(true, animated: true)
        
        UIView.performWithoutAnimation {
            self.collectionView?.reloadSections(IndexSet(integer: 0))
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        guard coordinator.animate(alongsideTransition: { context in self.collectionView?.reloadData() }, completion: nil)
            else { return }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: IBAction Implementation
    
    @IBAction func longPress(_ sender: UILongPressGestureRecognizer) {
        
        if (sender.state != .began) { return }
        
        let tapPoint = sender.location(in: collectionView)
        
        if (collectionView?.indexPathForItem(at: tapPoint) == nil) { return }

        let selectedObject = coreData.object(at: collectionView!.indexPathForItem(at: tapPoint)!)
        
        present({ [unowned self] in

            $0.addAction(UIAlertAction(title: "Unsubscribe", style: .destructive) { alert in
                (UIApplication.shared.delegate as! AppDelegate).unsubscribe(channelID: selectedObject.id!)
            })
            
            $0.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            
            $0.popoverPresentationController?.sourceView = self.collectionView
            $0.popoverPresentationController?.sourceRect = CGRect(x: tapPoint.x, y: tapPoint.y, width: 1.0, height: 1.0)
            return $0
            
        } (UIAlertController(title: "Option for \(selectedObject.name!)'s Channel", message: nil, preferredStyle: .actionSheet)), animated: true, completion: nil)
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
    
    
    // MARK: VideoProtocol Implementation
    
    func loadVideo(result: VideoResult) {
        
        if let videoVC = self.storyboard?.instantiateViewController(withIdentifier: "VideoPlayerVC") as? VideoPlayerVC {
            
            videoVC.result = result
            
            Cloud.get(video: result.videoid, withQuality: "sd", details: { (detail) in
                
                DispatchQueue.main.async {
                    videoVC.detail = detail
                    videoVC.videoController?.player = AVPlayer(url: detail?.mp4 ?? URL(string: "")!)
                }
            })
            
            DispatchQueue.main.async {
                self.navigationController?.pushViewController(videoVC, animated: true)
            }
        }
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
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SubscriptionCell", for: indexPath) as! SubscriptionCell
        
        cell.name.text = coreData.object(at: indexPath).name
        cell.thumbnail.image = UIImage(contentsOfFile: "\(DocumentsDirectory)/\(coreData.object(at: indexPath).id!).jpg")

        return cell
    }
    
    
    // MARK: UICollectionViewDelegate Implementation
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if let nextVC = self.storyboard?.instantiateViewController(withIdentifier: "ChannelVC") as? ChannelVC {
            
            let tempObject = coreData.object(at: indexPath)
            
            nextVC.delegate = self
            nextVC.metadata = (tempObject.name!, tempObject.id!)
            
            // Configure the transition from one view controller to the other
            let presentationController = SlideUpTransition(presentedViewController: nextVC, presenting: self)
            nextVC.transitioningDelegate = presentationController
            
            self.present(nextVC, animated: true, completion: nil)
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        
        (collectionView.cellForItem(at: indexPath) as! SubscriptionCell).thumbnail.alpha = 0.8
    }

    override func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {

        (collectionView.cellForItem(at: indexPath) as! SubscriptionCell).thumbnail.alpha = 1
    }
}
