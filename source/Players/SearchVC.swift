/*
 Developer : Warren Seto
 Classes   : SearchVC
 Project   : Players App (v2)
 */

import UIKit
import AVFoundation

final class SearchVC: UICollectionViewController, UICollectionViewDelegateFlowLayout, UICollectionViewDataSourcePrefetching, UITextFieldDelegate, SearchProtocol {
    
    
    // MARK: Properties
    
    private let AppController : AppDelegate = UIApplication.shared.delegate as! AppDelegate
    
    private lazy var videoResults : [VideoResult] = []
    
    private lazy var payload = SearchQuery()
    
    private lazy var savedOptions = [0, 0, 0]
    
    private lazy var SearchQueue:DispatchQueue = DispatchQueue(label: "search", qos: .background, target: nil)
    
    private weak var searchBarHeader:UICollectionReusableView?
    
    
    // MARK: UIViewController Implementation
    
    override func viewDidLoad() {
        
        super.viewDidLoad()

        (collectionViewLayout as! UICollectionViewFlowLayout).sectionHeadersPinToVisibleBounds = true
        
        (collectionViewLayout as! UICollectionViewFlowLayout).minimumLineSpacing = UIDevice.current.userInterfaceIdiom == .phone ? 0 : 4
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        
        coordinator.animate(alongsideTransition: { [weak self] _ in
            
            if self?.videoResults.count != 0 {
                self?.collectionView?.performBatchUpdates(nil, completion: nil)
            }
            
        }, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let selected = collectionView?.indexPathsForSelectedItems?.first {
            let videoVC = segue.destination as! VideoPlayerVC
            videoVC.result = videoResults[selected.row]
            
            Cloud.get(video: videoResults[selected.row].videoid, withQuality: "sd", details: { (detail) in
                DispatchQueue.main.async {
                    videoVC.videoController?.player = AVPlayer(url: detail?.mp4 ?? URL(string: "")!)
                }
                
                videoVC.detail = detail
            })
        }
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
                
                self.AppController.cacheVideo(result: selectedResult, withQuality: "sd", andCacheImage: cacheImage)
            })
            
            $0.addAction(UIAlertAction(title: "Download HD", style: .default) { alert in
                
                if self.AppController.isCachedVideo(ID: selectedResult.videoid) { return }
                
                let cacheImage:UIImage? = UIDevice.current.userInterfaceIdiom == .phone ? (self.collectionView?.cellForItem(at: selectedIndexPath) as! CompactVideoCell).thumbnail.image : (self.collectionView?.cellForItem(at: selectedIndexPath) as! LargeVideoCell).thumbnail.image
                
                self.AppController.cacheVideo(result: selectedResult, withQuality: "hd", andCacheImage: cacheImage)
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
    
    @IBAction func filterSearch(_ sender: Any) {
        
        if let nextVC = self.storyboard?.instantiateViewController(withIdentifier: "SearchFilterVC") as? SearchFilterVC {
            
            nextVC.delegate = self
            nextVC.selectedOptions = savedOptions
            
            let presentationController = SlideUpTransition(presentedViewController: nextVC, presenting: self)
            nextVC.transitioningDelegate = presentationController
            
            self.present(nextVC, animated: true, completion: nil)
        }
    }
    
    
    // MARK: SearchVC Functions
    
    private func performSearch() {
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        Cloud.get(search: payload) { (searchResults) in
            
            if let validResults = searchResults {
                self.videoResults = validResults.results
                self.payload.nextPageToken = validResults.nextToken
                
            } else {
                self.videoResults = []
            }
            
            DispatchQueue.main.async {
                UIView.performWithoutAnimation {
                    self.collectionView?.reloadData()
                }
                
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
        }
    }
    
    func updateSearch(newOrder: String, newDuration: String, newOptions: [Int]) {
        
        savedOptions = newOptions
        
        payload.nextPageToken = " "
        
        var optionsArray:[String] = []
        
        if newOrder != "" {
            optionsArray.append("order=\(newOrder)")
        }
        
        if newDuration != "" {
            optionsArray.append("videoDuration=\(newDuration)")
        }
        
        payload.option = optionsArray.joined(separator: "&")
        
        performSearch()
    }
    
    
    // MARK: UITextFieldDelegate Implementation
    
    internal func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        textField.resignFirstResponder()
        
        if textField.text == payload.query {
            return true
        }
        
        payload.resetSearch(newQuery: textField.text!)
        savedOptions = [0, 0, 0]
        
        performSearch()
        
        return true
    }
    
    
    // MARK: UICollectionViewDataSource Implementation
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return videoResults.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        if searchBarHeader == nil {
            searchBarHeader = {
                $0.searchField.delegate = self
                $0.layer.zPosition = 1
                
                return $0
            } (collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "SearchHeaderView", for: indexPath) as! SearchHeaderView)
        }
        
        return searchBarHeader!
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
        }
            
        else {
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

    
    // MARK: UICollectionViewDataSourcePrefetching Implementation
    
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        
        SearchQueue.async {
            
            if let triggerLoad = indexPaths.first?.row, triggerLoad > self.videoResults.count - 7 {
                
                DispatchQueue.main.async {
                    self.collectionView?.isPrefetchingEnabled = false
                    UIApplication.shared.isNetworkActivityIndicatorVisible = true
                }

                /* Search Async */
                Cloud.get(search: self.payload, results: { (searchResults) in
                    
                    if let validResults = searchResults {
                        self.videoResults += validResults.results
                        self.payload.nextPageToken = validResults.nextToken
                        
                        DispatchQueue.main.async {
                            UIView.performWithoutAnimation {
                                self.collectionView?.reloadData()
                            }
                        }
                    }
                    
                    DispatchQueue.main.async {
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                        self.collectionView?.isPrefetchingEnabled = true
                    }
                })
            }
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
    
    internal func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return UIDevice.current.userInterfaceIdiom == .phone ?
            CGSize(width: UIScreen.main.bounds.width - 10, height: 100) :
            CGSize(width: 320, height: 235)
    }
    
    internal func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIDevice.current.userInterfaceIdiom == .phone ? UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0) : UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
    }
}
