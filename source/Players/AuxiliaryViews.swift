/*
 Developer : Warren Seto
 Classes   : CompactVideoCell, LargeVideoCell, SubscriptionCell, SearchHeaderView, VideoTitleCell, VideoDescriptionCell, VideoIconCell
 Protocols : VideoProtocol, SearchProtocol
 Extensions: UICollectionViewController, UINavigationController, String -> heightWithConstrainedWidth(...)
 Project   : Players App (v2)
 */

import UIKit

extension UICollectionViewController {

    open override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
}

extension UINavigationController {
    
    open override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    open override var prefersStatusBarHidden: Bool {
        return false
    }
}

extension String {
    
    func heightWithConstrainedWidth(width: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude),
        boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSAttributedStringKey.font: font], context: nil)
        
        return boundingBox.height
    }
}

protocol VideoProtocol {
    func loadVideo(result: VideoResult)
}

protocol SearchProtocol {
    func updateSearch(newOrder: String, newDuration: String, newOptions: [Int])
}

final class CompactVideoCell : UICollectionViewCell {

    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var thumbnail: UIImageView!
    @IBOutlet weak var views: UILabel!
    @IBOutlet weak var duration: UILabel!
    @IBOutlet weak var channelName: UILabel!
}

final class LargeVideoCell : UICollectionViewCell {

    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var thumbnail: UIImageView!
    @IBOutlet weak var subtitle: UILabel!
    @IBOutlet weak var duration: UILabel!
}

final class SubscriptionCell : UICollectionViewCell {

    @IBOutlet weak var thumbnail: UIImageView!
    @IBOutlet weak var name: UILabel!
}

final class SearchHeaderView : UICollectionReusableView {

    @IBOutlet weak var headerStyle: UIVisualEffectView!
    @IBOutlet weak var searchField: UITextField!
}

final class VideoTitleCell : UICollectionViewCell {
    @IBOutlet weak var title: UILabel!
}

final class VideoDescriptionCell : UICollectionViewCell {
    @IBOutlet weak var detail: UITextView!
}

final class VideoIconCell : UICollectionViewCell {
    @IBOutlet weak var thumbnail: UIImageView!
    @IBOutlet weak var info: UILabel!
}
