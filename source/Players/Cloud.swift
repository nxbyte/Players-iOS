//  Warren Seto
//  Cloud.swift
//  Players App for Youtube
//  A Private, Barebones Network API is included for GET requests

import UIKit

public final class Server
{
    /** Returns a string with the url of the video's MP4 */
    class func videoURL (url:String, _ quaility:Int, _ response:(String)->())
    {
        Network.GET("https://custom_backend.com/video?u=\(url)&q=\(quaility)p")
        {
            (code, data) -> () in
            
            if (code == 200) { response(String(data: data!, encoding: NSUTF8StringEncoding)!) }
                
            else
            {
                dispatch_async(dispatch_get_main_queue()) { UIAlertView(title: "Video Unavailable", message: "", delegate: nil, cancelButtonTitle: "Okay").show() }
                response("")
            }
        }
    }
    
    /** Returns an array of videos from a query */
    class func search (query:String, _ indexAt:Int, _ response:([Video])->())
    {
        Network.GET("https://custom_backend.com/search?s=\(query.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.alphanumericCharacterSet())!)&i=\(indexAt)")
        {
            (code, data) -> () in
            
            if (code == 200) { response(self.parse(String(data: data!, encoding: NSUTF8StringEncoding)!)) }
            else { response([]) }
        }
    }
    
    /** Returns an array of recent videos from an associated Channel ID */
    class func sub (subID:String, _ response:([Video])->())
    {
        Network.GET("https://custom_backend.com/channel?c=\(subID)")
        {
            (code, data) -> () in
            
            if (code == 200) { response(self.parse(String(data: data!, encoding: NSUTF8StringEncoding)!)) }
            else { response([]) }
        }
    }
    
    /** Returns an array of recent videos from an array of Channel IDs */
    class func subs (subs:[String], _ response:([Video])->())
    {
        let temp = subs.joinWithSeparator(",")
        
        Network.GET("https://custom_backend.com/now?c=\(temp)")
        {
            (code, data) -> () in
                
            if (code == 200) { response(self.parse(String(data: data!, encoding: NSUTF8StringEncoding)!)) }
            else { response([]) }
        }
    }
    
    /** Returns a tuple with urls associated with a Channel ID's: Official Name and Thumbnail */
    class func channelData (ID:String, _ response:(String, String)->())
    {
        Network.GET("https://custom_backend.com/chInfo?c=\(ID)")
        {
            (code, data) -> () in
            
            if (code == 200)
            {
                let output = String(data: data!, encoding: NSUTF8StringEncoding)!.componentsSeparatedByString("///:///")
                response(output[0], output[1])
            }
        }
    }
    
    private class func parse (input:String) -> [Video]
    {
        var output:[Video] = [], count = 0
        let tempArray = input.componentsSeparatedByString("///:///")
        while (count < tempArray.count - 7)
        {
            output.append(Video(title:tempArray[count], thumbnail:tempArray[count+1], time: tempArray[count+2], views:"\(tempArray[count+3]) views", url: tempArray[count+4], channelName:tempArray[count+5], channelID:tempArray[count+6]))
            
            count += 7
        }
        
        return output
    }
    
    /** Returns a video's ID from a complete youtube URL. Example: "https://www.youtube.com/watch?v=jNQXAC9IVRw" returns "jNQXAC9IVRw" */
    class func videoID (url:NSURL) -> String { return url.absoluteString.componentsSeparatedByString("v=").last! }
    
    /** Returns a video's ID from a complete youtube URL. Example: "https://www.youtube.com/watch?v=jNQXAC9IVRw" returns "jNQXAC9IVRw" */
    class func videoID (url:String) -> String { return url.componentsSeparatedByString("v=").last! }
}

private final class Network
{
    class func GET (url: String, _ response:(Int?, NSData?)->())
    {
        NSURLSession.sharedSession().dataTaskWithURL(NSURL(string: url)!)
            {
                (data, res, err) -> Void in
                
                response(((res as? NSHTTPURLResponse)?.statusCode), data)
            }.resume()
    }
}

