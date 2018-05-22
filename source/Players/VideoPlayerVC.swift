/*
 Developer : Warren Seto
 Classes   : VideoPlayerVC
 Project   : Players App (v2)
 */

import UIKit
import AVFoundation
import AVKit
import CoreData

final class VideoPlayerVC : UICollectionViewController, UICollectionViewDelegateFlowLayout, UITextViewDelegate, VideoProtocol {
    
    
    // MARK: Properties
    
    private let AppController : AppDelegate = UIApplication.shared.delegate as! AppDelegate
    
    lazy var videoController : AVPlayerViewController? = { [unowned self] in
        $0.view.sizeToFit()
        $0.showsPlaybackControls = true
        return $0
    } (AVPlayerViewController())

    private lazy var isSubscribed : Bool = AppController.isSubscribed(ID: result.channelid)
    
    private lazy var cellCount : Int = 1
    
    var result : VideoResult!
    
    var detail : VideoDetail! {
        didSet {
            if self.cellCount == 1 {
                self.cellCount = 2
                DispatchQueue.main.async {
                    try? AVAudioSession.sharedInstance().setActive(true)
                    self.collectionView?.insertItems(at: [IndexPath(row: 1, section: 0)])
                    self.collectionView?.reloadItems(at: [IndexPath(row: 1, section: 1), IndexPath(row: 2, section: 1)])
                    self.videoController?.player?.play()
                }
                
                NotificationCenter.default.addObserver(forName: .UIApplicationDidEnterBackground, object: nil, queue: .current) { [weak self] _ in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: {
                        self?.videoController?.player?.play()
                    })
                }
            }
        }
    }
    
    
    // MARK: UIViewController Implementation
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        
        UIApplication.shared.beginReceivingRemoteControlEvents()
        
        (self.collectionViewLayout as! UICollectionViewFlowLayout).sectionHeadersPinToVisibleBounds = true
    }
    
    override func didMove(toParentViewController parent: UIViewController?) {
        
        if (parent == nil) {
            try? AVAudioSession.sharedInstance().setActive(false)
            UIApplication.shared.endReceivingRemoteControlEvents()
            
            DispatchQueue.global(qos: .userInitiated).async {
                self.videoController?.player?.replaceCurrentItem(with: nil)
                self.videoController = nil
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.videoController?.player?.play()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.videoController?.player?.pause()
    }
    
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        
        coordinator.animate(alongsideTransition: { [unowned self] _ in
            
            self.collectionView?.performBatchUpdates(nil, completion: nil)
            
        }, completion: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // General UIKit Functions
    
    override func remoteControlReceived(with event: UIEvent?) {
        
        switch (event!.subtype) {
        case .remoteControlPause:
            videoController?.player?.pause()
            break
        case .remoteControlPlay:
            videoController?.player?.play()
            break
        case .remoteControlNextTrack:
            videoController?.player!.seek(to: CMTimeAdd((videoController?.player!.currentTime())!, CMTimeMakeWithSeconds(15, 1)))
            break
        case .remoteControlPreviousTrack:
            videoController?.player!.seek(to: CMTimeSubtract((videoController?.player!.currentTime())!, CMTimeMakeWithSeconds(15, 1)))
            break
        default:
            break
        }
    }
    
    
    // MARK: IBAction Implementation
    
    @IBAction func shareVideo(_ sender: UIBarButtonItem) {
        self.present({
            $0.modalPresentationStyle = .popover
            $0.popoverPresentationController?.barButtonItem = sender
            return $0
        } (UIActivityViewController(activityItems: ["Take a look:\n", result.title + "\n", URL(string:"https://youtu.be/\(result.videoid)")!], applicationActivities: nil)), animated: true, completion: nil)
    }
    
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        
        guard let urlComponents = URLComponents(url: URL, resolvingAgainstBaseURL: false),
        let queryItems = urlComponents.queryItems else {
            return true
        }
        
        if let newVideoID = queryItems.first(where: { $0.name == "v" })?.value {
            Cloud.get(video: newVideoID, withQuality: "sd", entry: { (entry) in
                if let validEntry = entry {
                    self.result = validEntry.result
                    self.detail = validEntry.detail
                    
                    DispatchQueue.main.async {
                        self.videoController?.player?.pause()
                        self.collectionView?.reloadItems(at: [IndexPath(row: 0, section: 0), IndexPath(row: 0, section: 1), IndexPath(row: 1, section: 0), IndexPath(row: 1, section: 1), IndexPath(row: 2, section: 1)])
                        self.videoController?.player?.replaceCurrentItem(with: AVPlayerItem(url: validEntry.detail.mp4!))
                        self.videoController?.player?.play()
                    }
                }
            })
            return false
        } else {
            return true
        }
    }

    
    // MARK: VideoProtocol Implementation
    
    func loadVideo(result: VideoResult) {
        
        self.result = result
        self.collectionView?.reloadItems(at: [IndexPath(row: 0, section: 0), IndexPath(row: 0, section: 1)])
        
        DispatchQueue.global(qos: .userInitiated).async {
           self.videoController?.player?.replaceCurrentItem(with: nil)
        }
        
        Cloud.get(video: result.videoid, withQuality: "sd", details: { (detail) in
            
            if let validDetail = detail {
                DispatchQueue.main.async {
                    self.detail = validDetail
                    self.collectionView?.reloadItems(at: [IndexPath(row: 1, section: 0), IndexPath(row: 1, section: 1), IndexPath(row: 2, section: 1)])
                    self.videoController?.player?.replaceCurrentItem(with: AVPlayerItem(url: validDetail.mp4 ?? URL(string: "")!))
                    self.videoController?.player?.play()
                }
            }
        })
    }

    
    // MARK: UICollectionViewDataSource Implementation
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 {
            return cellCount
        } else {
            return 6
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        let videoCell = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "VideoPlayerHeaderCell", for: indexPath)
        
        if indexPath.section == 0 {
            videoController?.view.frame = videoCell.frame
            
            if let videoInHeader = videoController?.view {
                videoCell.addSubview(videoInHeader)
            }
        }
        
        return videoCell
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    
        if (indexPath.section == 1 && cellCount == 2) {
            switch (indexPath.row) {
                case 3:
                    if let nextVC = self.storyboard?.instantiateViewController(withIdentifier: "ChannelVC") as? ChannelVC {
                        
                        nextVC.delegate = self
                        nextVC.metadata = (result.channelname, result.channelid)
                        
                        // Configure the transition from one view controller to the other
                        let presentationController = SlideUpTransition(presentedViewController: nextVC, presenting: self)
                        nextVC.transitioningDelegate = presentationController
                        
                        self.present(nextVC, animated: true, completion: nil)
                }
                
                case 4:
                    if isSubscribed {
                        AppController.unsubscribe(channelID: result.channelid)
                    } else {
                        AppController.subscribe(channelName: result.channelname, withID: result.channelid)
                    }
                
                    isSubscribed = !isSubscribed
                    collectionView.reloadItems(at: [indexPath])
                
                case 5:
                    if self.AppController.isCachedVideo(ID: result.videoid) { return }

                    self.AppController.addCacheVideo(result: result, withQuality: "sd", andCacheImage: nil)
                
                default:
                    break
            }
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell:UICollectionViewCell!
        
        if (indexPath.section == 0) {
            switch indexPath.row {
            case 0:
                cell = collectionView.dequeueReusableCell(withReuseIdentifier: "VideoTitleCell", for: indexPath)
                (cell as! VideoTitleCell).title.text = result.title
            case 1:
                cell = collectionView.dequeueReusableCell(withReuseIdentifier: "VideoDescriptionCell", for: indexPath)
                (cell as! VideoDescriptionCell).detail.text = detail!.description
                (cell as! VideoDescriptionCell).detail.delegate = self
            default:
                fatalError("Invalid Cell in VideoPlayerVC Section 0 Row \(indexPath.row)")
            }
        } else {
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: "VideoIconCell", for: indexPath)
            
            switch indexPath.row {
            case 0:
                (cell as! VideoIconCell).info.text = "\(result.viewcount) views"
                (cell as! VideoIconCell).thumbnail.image = #imageLiteral(resourceName: "Logo_Icon_Gray")
            case 1:
                (cell as! VideoIconCell).info.text = detail?.like ?? "-"
                (cell as! VideoIconCell).thumbnail.image = #imageLiteral(resourceName: "Like_Icon")
            case 2:
                (cell as! VideoIconCell).info.text = detail?.dislike ?? "-"
                (cell as! VideoIconCell).thumbnail.image = #imageLiteral(resourceName: "Dislike_Icon")
            case 3:
                (cell as! VideoIconCell).info.text = "Other videos"
                (cell as! VideoIconCell).thumbnail.image = #imageLiteral(resourceName: "Video_Icon")
            case 4:
                (cell as! VideoIconCell).info.text = isSubscribed ? "Unsubscribe" : "Subscribe"
                (cell as! VideoIconCell).thumbnail.image = #imageLiteral(resourceName: "Star_Icon")
            case 5:
                (cell as! VideoIconCell).info.text = "Cache"
                (cell as! VideoIconCell).thumbnail.image = #imageLiteral(resourceName: "Cache_Icon")
            default:
                fatalError("Invalid Cell in VideoPlayerVC Section 1")
            }
        }
        
        return cell
    }

    
    // MARK: UICollectionViewDelegate Implementation
    
    override func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        if (indexPath.row > 2) {
            (collectionView.cellForItem(at: indexPath) as? VideoIconCell)?.thumbnail.alpha = 0.7
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        if (indexPath.row > 2) {
            (collectionView.cellForItem(at: indexPath) as? VideoIconCell)?.thumbnail.alpha = 1.0
        }
    }
    
    
    // MARK: UICollectionViewDelegateFlowLayout Implementation
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return section == 0 ? CGSize(width: self.view.frame.width, height: 240.0) : CGSize.zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        if (indexPath.section == 0) {
            switch indexPath.row {
            case 0:
                return CGSize(width: self.view.frame.width - 30, height: result.title.heightWithConstrainedWidth(width: self.view.frame.width - 30, font: UIFont.preferredFont(forTextStyle: .headline)))
                
            case 1:
                return CGSize(width: self.view.frame.width - 20, height: max(detail!.description!.heightWithConstrainedWidth(width: self.view.frame.width - 80, font: UIFont.preferredFont(forTextStyle: .subheadline)), 80))
                
            default:
                fatalError("Invalid Cell Height in VideoPlayerVC Section 0 Row \(indexPath.row)")
            }
        } else {
            return CGSize(width: (self.view.frame.width - 20)/3.0, height: 105.0)
        }
    }
}
