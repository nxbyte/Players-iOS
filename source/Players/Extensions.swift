// Warren Seto
// Extensions: NSUserDefaults and NSFileManager
// Version 1.0

import UIKit
import Foundation

public final class LocalStore
{
    /** (Required) Sets up a local store key for use. Use this in AppDelegate */
    class func prepare(_ storeKey:String)
    {
        if (UserDefaults.standard.object(forKey: storeKey) == nil)
        {
            UserDefaults.standard.set(NSMutableDictionary(), forKey: storeKey)
        }
    }
    
    /** Sets a string to the local store */
    class func set(_ storeKey:String, dictKey:String, dictValue:String)
    {
        var temp = UserDefaults.standard.object(forKey: storeKey) as! Dictionary<String, String>
        temp[dictKey] = dictValue
        UserDefaults.standard.set(temp, forKey: storeKey)
    }
    
    /** Sets a NSDictionary object to local store */
    class func setDictionary(_ storeKey:String, dict:NSDictionary)
    {
        UserDefaults.standard.set(dict, forKey: storeKey)
    }
    
    /** Removes a value from the local store */
    class func remove(_ storeKey:String, dictKey:String)
    {
        var temp = UserDefaults.standard.object(forKey: storeKey) as! Dictionary<String, String>
        temp.removeValue(forKey: dictKey)
        UserDefaults.standard.set(temp, forKey: storeKey)
    }
    
    /** Removes a local store key; after deleting the data is unrecoverable */
    class func purge(_ storeKey:String)
    {
        UserDefaults.standard.removeObject(forKey: storeKey)
    }
    
    /** Returns an array of String keys from local store */
    class func keys(_ storeKey:String) -> [String]
    {
        return (UserDefaults.standard.object(forKey: storeKey) as AnyObject).allKeys as! [String]
    }
    
    /** Returns an array of String values from local store */
    class func values(_ storeKey:String) -> [String]
    {
        return (UserDefaults.standard.object(forKey: storeKey) as AnyObject).allValues as! [String]
    }
    
    /** Returns a NSDictionary object from local store */
    class func getDictionary(_ storeKey:String) -> NSDictionary
    {
        return UserDefaults.standard.object(forKey: storeKey) as! NSDictionary
    }
    
    /** Returns an Int for the length of the associated local store key */
    class func count(_ storeKey:String) -> Int
    {
        return (UserDefaults.standard.object(forKey: storeKey)! as AnyObject).allKeys.count
    }
}

public final class FileSystem
{
    /** Saves an NSData object to a directory with a given file name */
    class func saveFile(_ data:Data, folder:FileManager.SearchPathDirectory, fileName:String)
    {
        try? data.write(to: URL(fileURLWithPath: "\(NSSearchPathForDirectoriesInDomains(folder, .userDomainMask, true).first!)/\(fileName)"), options: [.atomic])
    }

    /** Removes a file from a directory; after deleting the data is unrecoverable */
    class func deleteFile(_ folder:FileManager.SearchPathDirectory, fileName:String)
    {
        do{
            return try FileManager.default.removeItem(atPath: "\(NSSearchPathForDirectoriesInDomains(folder, .userDomainMask, true).first!)/\(fileName)")
        }
        
        catch
        {
            print("[Error]: File isn't deleted")
        }
    }
    
    /** Returns an NSData object with a given directory and file name */
    class func getFile(_ folder:FileManager.SearchPathDirectory, fileName:String) -> Data?
    {
        return (try? Data(contentsOf: URL(fileURLWithPath: "\(NSSearchPathForDirectoriesInDomains(folder, .userDomainMask, true).first!)/\(fileName)")))
    }
    
    /** Returns a String with the complete path from a given directory and file name */
    class func getPath(_ folder:FileManager.SearchPathDirectory, fileName:String) -> String
    {
        return "\(NSSearchPathForDirectoriesInDomains(folder, .userDomainMask, true).first!)/\(fileName)"
    }
    
    /** Returns a NSURL Object with the complete url from a given directory and file name. Includes the prefix file:// */
    class func getPath(_ folder:FileManager.SearchPathDirectory, fileName:String) -> URL?
    {
        return URL(fileURLWithPath:"\(NSSearchPathForDirectoriesInDomains(folder, .userDomainMask, true).first!)/\(fileName)")
    }
    
    /** Returns an array of Strings with the name of the files from a general directory */
    class func listDirectory(_ folder:FileManager.SearchPathDirectory) -> [String]
    {
        do{
            return try FileManager.default.contentsOfDirectory(atPath: "\(NSSearchPathForDirectoriesInDomains(folder, .userDomainMask, true).first!)") 
        }
        
        catch
        {
            print("[Error]: Directory not present")
            return []
        }
    }
    
    /** Returns an array of Strings with the name of the files from a specified directory */
    class func listDirectory(_ folder:FileManager.SearchPathDirectory, subFolder:String) -> [String]
    {
        do{
            return try FileManager.default.contentsOfDirectory(atPath: "\(NSSearchPathForDirectoriesInDomains(folder, .userDomainMask, true).first!)/\(subFolder)")
        }
        
        catch
        {
            print("[Error]: Directory not present")
            return []
        }
    }
    
    /** Returns a double that is associated with the size of a given file in a specified directory */
    class func fileSize(_ folder:FileManager.SearchPathDirectory, fileName:String) -> Double
    {
        do
        {
            return Double((try FileManager.default.attributesOfItem(atPath: "\(NSSearchPathForDirectoriesInDomains(folder, .userDomainMask, true).first!)/\(fileName)") as NSDictionary!).object(forKey: FileAttributeKey.size) as! Int!) / 1000000.0
        }
        
        catch
        {
            return 0.0
        }
    }
    
    /** Returns a Boolean value that indicates whether a file or directory exists at a specified path. */
    class func fileExist(_ path:String) -> Bool
    {
        return FileManager.default.fileExists(atPath: path)
    }
}


