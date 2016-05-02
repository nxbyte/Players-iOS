// Warren Seto
// Extensions: NSUserDefaults and NSFileManager
// Version 1.0

import UIKit
import Foundation

public final class LocalStore
{
    /** (Required) Sets up a local store key for use. Use this in AppDelegate */
    class func prepare(storeKey:String)
    {
        if (NSUserDefaults.standardUserDefaults().objectForKey(storeKey) == nil)
        {
            NSUserDefaults.standardUserDefaults().setObject(NSMutableDictionary(), forKey: storeKey)
        }
    }
    
    /** Sets a string to the local store */
    class func set(storeKey:String, dictKey:String, dictValue:String)
    {
        let temp = (NSUserDefaults.standardUserDefaults().objectForKey(storeKey)?.mutableCopy()) as! NSMutableDictionary
        temp.setValue(dictValue, forKey: dictKey)
        NSUserDefaults.standardUserDefaults().setObject(temp, forKey: storeKey)
    }
    
    /** Sets a NSDictionary object to local store */
    class func setDictionary(storeKey:String, dict:NSDictionary)
    {
        NSUserDefaults.standardUserDefaults().setObject(dict, forKey: storeKey)
    }
    
    /** Removes a value from the local store */
    class func remove(storeKey:String, dictKey:String)
    {
        let temp = (NSUserDefaults.standardUserDefaults().objectForKey(storeKey)?.mutableCopy()) as! NSMutableDictionary
        temp.removeObjectForKey(dictKey)
        NSUserDefaults.standardUserDefaults().setObject(temp, forKey: storeKey)
    }
    
    /** Removes a local store key; after deleting the data is unrecoverable */
    class func purge(storeKey:String)
    {
        NSUserDefaults.standardUserDefaults().removeObjectForKey(storeKey)
    }
    
    /** Returns an array of String keys from local store */
    class func keys(storeKey:String) -> [String]
    {
        return NSUserDefaults.standardUserDefaults().objectForKey(storeKey)?.allKeys as! [String]
    }
    
    /** Returns an array of String values from local store */
    class func values(storeKey:String) -> [String]
    {
        return NSUserDefaults.standardUserDefaults().objectForKey(storeKey)?.allValues as! [String]
    }
    
    /** Returns a NSDictionary object from local store */
    class func getDictionary(storeKey:String) -> NSDictionary
    {
        return NSUserDefaults.standardUserDefaults().objectForKey(storeKey) as! NSDictionary
    }
    
    /** Returns an Int for the length of the associated local store key */
    class func count(storeKey:String) -> Int
    {
        return NSUserDefaults.standardUserDefaults().objectForKey(storeKey)!.allKeys.count
    }
}

public final class FileSystem
{
    /** Saves an NSData object to a directory with a given file name */
    class func saveFile(data:NSData, folder:NSSearchPathDirectory, fileName:String)
    {
        data.writeToFile("\(NSSearchPathForDirectoriesInDomains(folder, .UserDomainMask, true).first!)/\(fileName)", atomically: true)
    }

    /** Removes a file from a directory; after deleting the data is unrecoverable */
    class func deleteFile(folder:NSSearchPathDirectory, fileName:String)
    {
        do{
            return try NSFileManager.defaultManager().removeItemAtPath("\(NSSearchPathForDirectoriesInDomains(folder, .UserDomainMask, true).first!)/\(fileName)")
        }
        
        catch
        {
            print("[Error]: File isn't deleted")
        }
    }
    
    /** Returns an NSData object with a given directory and file name */
    class func getFile(folder:NSSearchPathDirectory, fileName:String) -> NSData?
    {
        return NSData(contentsOfFile: "\(NSSearchPathForDirectoriesInDomains(folder, .UserDomainMask, true).first!)/\(fileName)")
    }
    
    /** Returns a String with the complete path from a given directory and file name */
    class func getPath(folder:NSSearchPathDirectory, fileName:String) -> String
    {
        return "\(NSSearchPathForDirectoriesInDomains(folder, .UserDomainMask, true).first!)/\(fileName)"
    }
    
    /** Returns a NSURL Object with the complete url from a given directory and file name. Includes the prefix file:// */
    class func getPath(folder:NSSearchPathDirectory, fileName:String) -> NSURL?
    {
        return NSURL(fileURLWithPath:"\(NSSearchPathForDirectoriesInDomains(folder, .UserDomainMask, true).first!)/\(fileName)")
    }
    
    /** Returns an array of Strings with the name of the files from a general directory */
    class func listDirectory(folder:NSSearchPathDirectory) -> [String]
    {
        do{
            return try NSFileManager.defaultManager().contentsOfDirectoryAtPath("\(NSSearchPathForDirectoriesInDomains(folder, .UserDomainMask, true).first!)") 
        }
        
        catch
        {
            print("[Error]: Directory not present")
            return []
        }
    }
    
    /** Returns an array of Strings with the name of the files from a specified directory */
    class func listDirectory(folder:NSSearchPathDirectory, subFolder:String) -> [String]
    {
        do{
            return try NSFileManager.defaultManager().contentsOfDirectoryAtPath("\(NSSearchPathForDirectoriesInDomains(folder, .UserDomainMask, true).first!)/\(subFolder)")
        }
        
        catch
        {
            print("[Error]: Directory not present")
            return []
        }
    }
    
    /** Returns a double that is associated with the size of a given file in a specified directory */
    class func fileSize(folder:NSSearchPathDirectory, fileName:String) -> Double
    {
        do
        {
            return Double((try NSFileManager.defaultManager().attributesOfItemAtPath("\(NSSearchPathForDirectoriesInDomains(folder, .UserDomainMask, true).first!)/\(fileName)") as NSDictionary!).objectForKey(NSFileSize) as! Int!) / 1000000.0
        }
        
        catch
        {
            return 0.0
        }
    }
    
    /** Returns a Boolean value that indicates whether a file or directory exists at a specified path. */
    class func fileExist(path:String) -> Bool
    {
        return NSFileManager.defaultManager().fileExistsAtPath(path)
    }
}


