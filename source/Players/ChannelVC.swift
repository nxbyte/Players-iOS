/*
 Developer : Warren Seto
 Classes   : ChannelVC
 Project   : Players App (v2)
 */

import UIKit
import AVFoundation

final class ChannelVC: UICollectionViewController, UICollectionViewDelegateFlowLayout, UITextFieldDelegate {
    
    
    // MARK: Properties
    
    private let AppController : AppDelegate = UIApplication.shared.delegate as! AppDelegate
    
    private lazy var videoResults : [VideoResult] = []
    
    var metadata:(name: String, id: String)!
    
    var delegate:VideoProtocol?
    
    private weak var searchBarHeader:UICollectionReusableView?
    
    
    // MARK: UIViewController Implementation
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        loadChannel()
        
        (collectionViewLayout as! UICollectionViewFlowLayout).minimumLineSpacing = UIDevice.current.userInterfaceIdiom == .phone ? 0 : 4
        
        setViewController(with: self.traitCollection)
    }
    
    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        
        super.willTransition(to: newCollection, with: coordinator)

        setViewController(with: newCollection)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        
        coordinator.animate(alongsideTransition: { [unowned self] _ in
            
            if self.videoResults.count != 0 {
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
    
    
    // MARK: UITextFieldDelegate Implementation
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        textField.resignFirstResponder()
        
        Cloud.get(search: SearchQuery(query: textField.text!, nextPageToken: " ", option: "channelId=\(metadata.id)")) { (response) in
            
            self.videoResults = response.results
            // MARK : NEXTTOKEN NOT USED
                
            DispatchQueue.main.async {
                self.collectionView?.reloadSections(IndexSet(integer: 0))
            }
        }
        
        return true
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        
        loadChannel()
        
        return true
    }
    
    
    // MARK: ChannelVC Functions
    
    private func setViewController(with traitCollection:UITraitCollection) {
        self.preferredContentSize = CGSize(width: self.view.bounds.size.width, height: traitCollection.verticalSizeClass == .compact ? 200 : 400)
    }
    
    private func loadChannel() {
        
        Cloud.get(subscriptions: metadata.id) { (results) in
            self.videoResults = results
            
            DispatchQueue.main.async {
                UIView.performWithoutAnimation {
                    self.collectionView?.reloadSections(IndexSet(integer: 0))
                }
            }
        }
    }
    
    
    // MARK: UICollectionViewDataSource Implementation
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return videoResults.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        if searchBarHeader == nil {
            searchBarHeader = {
                $0.searchField.delegate = self
                $0.searchField.placeholder = " Search \(metadata.name)'s videos"
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
    
    
    // MARK: UICollectionViewDelegate Implementation
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        delegate?.loadVideo(result: videoResults[indexPath.row])
        
        dismiss(animated: true, completion: nil)
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
