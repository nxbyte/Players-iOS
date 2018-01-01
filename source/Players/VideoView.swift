//  Warren Seto
//  VideoView.swift
//  Players App for Youtube

import UIKit
import AVKit
import AVFoundation
//import MediaPlayer

final class VideoView : AVPlayerViewController
{
    /** Initializes an instance of a VideoView with a given String */
    init(url:String)
    {
        super.init(nibName: "", bundle: nil)
        
        player = AVPlayer(url: URL(string: url)!)
        
        NotificationCenter.default.addObserver(self, selector: #selector(VideoView.playerDidFinishPlaying(_:)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: player!.currentItem)
    }
    
    /** Initializes an instance of a VideoView with a given NSURL */
    init(URL:Foundation.URL)
    {
        super.init(nibName: "", bundle: nil)

        player = AVPlayer(url: URL)
        
        NotificationCenter.default.addObserver(self, selector: #selector(VideoView.playerDidFinishPlaying(_:)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: player!.currentItem)
    }
    
    override func viewDidLoad()
    {
        player!.play()
        
        UIApplication.shared.beginReceivingRemoteControlEvents()
        
        //MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = [MPMediaItemPropertyArtist : "Artist Name",  MPMediaItemPropertyTitle : "Video Title"] //(A Bug)
        
        NotificationCenter.default.addObserver(self, selector: #selector(VideoView.play), name: NSNotification.Name(rawValue: "PlayVideo"), object: nil)
    }
    
    @objc func playerDidFinishPlaying(_ notify:Notification)
    {
        self.dismiss(animated: true, completion:
        {
            NotificationCenter.default.removeObserver(self)
            UIApplication.shared.endReceivingRemoteControlEvents()
        })
    }
    
    @objc func play()
    {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC),
        execute: {
             self.player!.play()
        })
    }
    
    override func remoteControlReceived(with event: UIEvent?)
    {
        switch (event!.subtype)
        {
            case .remoteControlPause:
                player!.pause()
                break
            case .remoteControlPlay:
                player!.play()
                break
            case .remoteControlNextTrack:
                player!.seek(to: CMTimeAdd(player!.currentTime(), CMTimeMakeWithSeconds(15, 1)))
                break
            case .remoteControlPreviousTrack:
                player!.seek(to: CMTimeSubtract(player!.currentTime(), CMTimeMakeWithSeconds(15, 1)))
                break
            default:
                break
        }
    }
    
    /** Not required and recommended for use (Avoid) */
    required init(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
