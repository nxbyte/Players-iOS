//  Warren Seto
//  AppDelegate.swift
//  Players App for Youtube

import UIKit
import AVFoundation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate
{
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool
    {
        window?.tintColor = UIColor(red: 202/255.0, green: 90/255.0, blue: 94/255.0, alpha: 1)
        
        // Enable Background Audio for the App
        do { try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback) }
        catch { print("Error. Cannot be backgrounded!!!") }
        
        // Prepares LocalStorage for the App
        LocalStore.prepare("subs")
        LocalStore.prepare("cache")
        
         // Example 1
         let standardDict =
         [
            "UCddiUEpeqJcYeBxX1IVBKvQ" : "The Verge",
            "UC9-y-6csu5WGm29I7JiwpnA" : "Computerphile",
            "UC0vBXGSyV14uvJ4hECDOl0Q" : "Techquickie",
            "UCpOlOeQjj7EsVnDh3zuCgsA" : "adafruit",
            "UCX6b17PVsYBQ0ip5gyeme-Q" : "crashcourse",
            "UC3XTzVzaHQEd30rQbuvCtTQ" : "LastWeekTonight",
            "UCqg5FCR7NrpvlBWMXdt-5Vg" : "Escapist"
         ]

        LocalStore.setDictionary("subs", dict: standardDict as NSDictionary)
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication)
    {
        
    }

    func applicationDidEnterBackground(_ application: UIApplication)
    {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "PlayVideo"), object: nil)
    }

    func applicationWillEnterForeground(_ application: UIApplication)
    {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "PlayVideo"), object: nil)
    }

    func applicationDidBecomeActive(_ application: UIApplication)
    {
        
    }

    func applicationWillTerminate(_ application: UIApplication)
    {
        
    }
}

struct Video
{
    let title:String,
        thumbnail:String,
        time:String,
        views:String,
        url:String,
        channelName:String,
        channelID:String
}

func showLabel (_ text:String, viewController:UIViewController)
{
    let label = UILabel(frame: CGRect(origin: CGPoint(x: viewController.view.frame.width/2 - 40, y: viewController.view.frame.height/4), size: CGSize(width: 150, height: 100)))
    label.text = text
    label.alpha = 1
    viewController.view.addSubview(label)
    UIView.animate(withDuration: 5, animations: { label.alpha = 0 }, completion: { (flag) -> Void in label.removeFromSuperview() }) 
}



