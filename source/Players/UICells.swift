//  Warren Seto
//  CollectionViewCells.swift
//  Players App for Youtube

import UIKit

final class UICard: UICollectionViewCell
{
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var account: UILabel!
    @IBOutlet weak var time: UILabel!
    @IBOutlet weak var views: UILabel!
    @IBOutlet weak var image: UIImageView!
    
    override init(frame: CGRect)
    {
        super.init(frame: frame)
        image.image = UIImage(named: "placeholder_video")
    }

    required init?(coder aDecoder: NSCoder) { super.init(coder: aDecoder) }
}

final class ChannelPanel: UICollectionViewCell
{
    @IBOutlet weak var image: UIImageView!
    @IBOutlet weak var name: UILabel!
    
    override init(frame: CGRect)
    {
        super.init(frame: frame)
        image.image = UIImage(named: "placeholder_channel")
    }
    
    required init?(coder aDecoder: NSCoder) { super.init(coder: aDecoder) }
}