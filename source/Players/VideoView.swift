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
        
        player = AVPlayer(URL: NSURL(string: url)!)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(VideoView.playerDidFinishPlaying(_:)), name: AVPlayerItemDidPlayToEndTimeNotification, object: player!.currentItem)
    }
    
    /** Initializes an instance of a VideoView with a given NSURL */
    init(URL:NSURL)
    {
        super.init(nibName: "", bundle: nil)

        player = AVPlayer(URL: URL)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(VideoView.playerDidFinishPlaying(_:)), name: AVPlayerItemDidPlayToEndTimeNotification, object: player!.currentItem)
    }
    
    override func viewDidLoad()
    {
        player!.play()
        
        UIApplication.sharedApplication().beginReceivingRemoteControlEvents()
        
        //MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = [MPMediaItemPropertyArtist : "Artist Name",  MPMediaItemPropertyTitle : "Video Title"] //(A Bug)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(VideoView.play), name: "PlayVideo", object: nil)
    }
    
    func playerDidFinishPlaying(notify:NSNotification)
    {
        self.dismissViewControllerAnimated(true, completion:
        {
            NSNotificationCenter.defaultCenter().removeObserver(self)
            UIApplication.sharedApplication().endReceivingRemoteControlEvents()
        })
    }
    
    func play()
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(Double(NSEC_PER_SEC))), dispatch_get_main_queue(),
        {
             self.player!.play()
        })
    }
    
    override func remoteControlReceivedWithEvent(event: UIEvent?)
    {
        switch (event!.subtype)
        {
            case .RemoteControlPause:
                player!.pause()
                break
            case .RemoteControlPlay:
                player!.play()
                break
            case .RemoteControlNextTrack:
                player!.seekToTime(CMTimeAdd(player!.currentTime(), CMTimeMakeWithSeconds(15, 1)))
                break
            case .RemoteControlPreviousTrack:
                player!.seekToTime(CMTimeSubtract(player!.currentTime(), CMTimeMakeWithSeconds(15, 1)))
                break
            default:
                break
        }
    }
    
    /** Not required and recommended for use (Avoid) */
    required init(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
