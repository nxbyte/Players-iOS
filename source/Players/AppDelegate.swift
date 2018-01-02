/*
 Developer : Warren Seto
 Classes   : AppDelegate
 Project   : Players App (v2)
 */

import UIKit
import AVFoundation
import CoreData

@UIApplicationMain
final class AppDelegate: UIResponder, UIApplicationDelegate {

    
    // MARK: Properties
    
    var window: UIWindow?
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container: NSPersistentContainer = {
            return $0
        }(NSPersistentContainer(name: "Players"))
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    lazy var downloadsSession: URLSession = {
        let config = URLSessionConfiguration.background(withIdentifier: "\(Bundle.main.bundleIdentifier!).background")
        let delegateVC = ((self.window?.rootViewController as! UITabBarController).childViewControllers as! [UINavigationController]).last!.viewControllers.first as! CacheVC
        return URLSession(configuration: config, delegate: delegateVC, delegateQueue: nil)
    }()
    
    
    // MARK: UIApplicationDelegate Implementation
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        window?.tintColor = UIColor(red: 240/255.0, green: 76/255.0, blue: 60/255.0, alpha: 0.9) //  Manually set Application's Tint Color
        
        if let statusBar = UIApplication.shared.value(forKeyPath: "statusBarWindow.statusBar") as? UIView {

            let blurEffectView:UIVisualEffectView = {
                $0.layer.zPosition = -1
                $0.frame = statusBar.bounds
                $0.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                return $0
            } (UIVisualEffectView(effect: UIBlurEffect(style: .dark)))

            statusBar.addSubview(blurEffectView)
        }
        
        try? AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
        
        return true
    }
    
    // Special Function for handeling background downloads
    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        print("handleEventsForBackgroundURLSession: \(identifier)")
        
        completionHandler()
    }

    func applicationWillResignActive(_ application: UIApplication) {


    }

    func applicationDidEnterBackground(_ application: UIApplication) {


    }

    func applicationWillEnterForeground(_ application: UIApplication) {

    }

    func applicationDidBecomeActive(_ application: UIApplication) {

        
    }

    func applicationWillTerminate(_ application: UIApplication) {

        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                print("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    
    // MARK: Model & Core Data Properties
    
    /** Returns a comma seperated string for the device's subscriptions */
    var subscriptions : String {
        return UserDefaults.standard.string(forKey: "subscription-list") ?? ""
    }
    
    
    // MARK: Model & Core Data Implementation
    
    /** Subscribes and stores data for a given channel identifier.
     If components are unable to be stored, it will gracefully fail and display an error message */
    func subscribe (channelName name:String, withID ID: String) {
        persistentContainer.performBackgroundTask { (context) in
            let _:Subscription = {
                $0.name = name
                $0.id = ID
                return $0
            } (Subscription(context: context))
            
            do {
                try context.save()
                self.setSubscriptionCacheString(context: context)
                
                Cloud.get(channel: ID, details: { (details) in
                    if let validDetails = details {
                        URLSession.shared.dataTask(with: validDetails.thumbnail!, completionHandler: { (data, response, error) in
                            if data != nil {
                                do {
                                    let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
                                    try data?.write(to: DocumentsDirectory.appendingPathComponent("\(ID).jpg"))
                                } catch {
                                    print("Warning: Can't save Channel Thumbnail into documents directory")
                                }
                            }
                        }).resume()
                    } else {
                        print("Warning: Channel Details are invalid")
                    }
                })
            } catch {
                print("Warning: Could not subscribe to \(name) with ID: \(ID)")
            }
        }
    }
    
    /** Removes stored data and entries for a given channel identifier.
     If cached components are unable to be removed, it will gracefully fail and display an error message */
    func unsubscribe (channelID ID: String) {
        persistentContainer.performBackgroundTask { (context) in
            
            let fetch:NSFetchRequest<Subscription> = Subscription.fetchRequest()
            fetch.predicate = NSPredicate(format: "id == %@", ID)
            fetch.fetchLimit = 1
            
            if let result = try? fetch.execute() {
                context.delete(result.first!)
                
                do {
                    try context.save()
                    self.setSubscriptionCacheString(context: context)
                    
                    do {
                        let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
                        try FileManager.default.removeItem(at: DocumentsDirectory.appendingPathComponent("\(ID).jpg"))
                    } catch {
                        print("Warning: Could not remove thumbnail for channel ID: \(ID)")
                    }
                } catch {
                    print("Warning: Could not unsubscribe to channel ID: \(ID)")
                }
            }
        }
    }
    
    /** Returns whether a given channel identifier is found in the device's subscriptions */
    func isSubscribedTo (ID: String) -> Bool {
        let fetch:NSFetchRequest<Subscription> = Subscription.fetchRequest()
        fetch.predicate = NSPredicate(format: "id == %@", ID)
        fetch.fetchLimit = 1
        
        if let result = try? persistentContainer.viewContext.count(for: fetch) {
            return result == 1 ? true : false
        }
        
        return false
    }
    
    /** Cached data for a given video identifier.
     If components are unable to be stored, it will gracefully fail and display an error message */
    func cacheVideo(result:VideoResult, withQuality: String, andCacheImage image:UIImage?) {
        
        self.persistentContainer.performBackgroundTask { (context) in
            
            Cloud.get(video: result.videoid, withQuality: "sd", details: { (details) in
                
                guard let downloadURL = details?.mp4 else { return }
                
                let backgroundCacheTask = self.downloadsSession.downloadTask(with: downloadURL)
                backgroundCacheTask.taskDescription = result.videoid
                backgroundCacheTask.resume()
                
                let _:VideoCache = {
                    $0.downloaded = Date()
                    $0.duration = result.duration
                    $0.id = result.videoid
                    $0.name = result.title
                    $0.channelname = result.channelname
                    return $0
                } (VideoCache(context: context))
                
                do {
                    try context.save()
                    
                    if let validImage = image {
                        if let imageData = UIImageJPEGRepresentation(validImage, 1.0) {
                            let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
                            try? imageData.write(to: DocumentsDirectory.appendingPathComponent("\(result.videoid).jpg"))
                        }
                    } else {
                        URLSession.shared.dataTask(with: result.thumbnail, completionHandler: { (data, response, error) in
                            guard let validData = data else {
                                return
                            }
                            
                            let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
                            try? validData.write(to: DocumentsDirectory.appendingPathComponent("\(result.videoid).jpg"))
                        })
                    }
                } catch {
                    print("Warning: Could not cache video with ID: \(result.videoid)")
                }
            })
        }
    }

    /** Removes cached data for a given video identifier.
     If cached components are unable to be removed, it will gracefully fail and display an error message */
    func removeCacheVideo(ID: String) {
        persistentContainer.performBackgroundTask { (context) in
            
            let fetch:NSFetchRequest<VideoCache> = VideoCache.fetchRequest()
            fetch.predicate = NSPredicate(format: "id == %@", ID)
            fetch.fetchLimit = 1
            
            if let result = try? fetch.execute() {
                context.delete(result.first!)
                
                do {
                    try context.save()
                    
                    do {
                        let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
                        try FileManager.default.removeItem(at: DocumentsDirectory.appendingPathComponent("\(ID).jpg"))
                        try FileManager.default.removeItem(at: DocumentsDirectory.appendingPathComponent("\(ID).mp4"))
                    } catch {
                        print("Warning: Could not remove thumbnail and MP4 for video ID: \(ID)")
                    }
                } catch {
                    print("Warning: Could not delete mp4 for video ID: \(ID)")
                }
            }
        }
    }
    
    /** Returns whether a given video identifier is cached on the device */
    func isCachedVideo (ID: String) -> Bool {
        let fetch:NSFetchRequest<VideoCache> = VideoCache.fetchRequest()
        fetch.predicate = NSPredicate(format: "id == %@", ID)
        fetch.fetchLimit = 1
        
        if let result = try? persistentContainer.viewContext.count(for: fetch) {
            return result == 1 ? true : false
        }
        
        return false
    }
    
    
    // MARK: Model & Core Data Helper Functions
    
    /** Updates a cached string for all the subscriptions for the device */
    private func setSubscriptionCacheString(context: NSManagedObjectContext) {
        let fetch:NSFetchRequest<NSFetchRequestResult> = {
            $0.resultType = .dictionaryResultType
            $0.propertiesToFetch = ["id"]
            $0.returnsDistinctResults = true
            return $0
        } (NSFetchRequest<NSFetchRequestResult>(entityName: "Subscription"))
        
        do {
            if let stringDictonary:[[String:String]] = try context.fetch(fetch) as? [[String:String]] {
                UserDefaults.standard.set(stringDictonary.map { $0["id"]! }.joined(separator: ","), forKey: "subscription-list")
            }
        } catch {
            print(error)
        }
    }
}
