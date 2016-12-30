//  Warren Seto
//  Cloud.swift
//  Players App for Youtube
//  A Private, Barebones Network API is included for GET requests

import UIKit

public final class Server
{
    /** Returns a string with the url of the video's MP4 */
    class func videoURL (_ url:String, _ quaility:Int, _ response:@escaping (String)->())
    {
        Network.GET("https://custom_backend_test.com/video?u=\(url)&q=\(quaility)p")
        {
            (code, data) -> () in
            
            if (code == 200) { response(String(data: data!, encoding: String.Encoding.utf8)!) }
                
            else
            {
                DispatchQueue.main.async { UIAlertView(title: "Video Unavailable", message: "", delegate: nil, cancelButtonTitle: "Okay").show() }
                response("")
            }
        }
    }
    
    /** Returns an array of videos from a query */
    class func search (_ query:String, _ indexAt:Int, _ response:@escaping ([Video])->())
    {
        Network.GET("https://custom_backend_test.com/search?s=\(query.addingPercentEncoding(withAllowedCharacters: CharacterSet.alphanumerics)!)&i=\(indexAt)")
        {
            (code, data) -> () in
            
            if (code == 200) { response(self.parse(String(data: data!, encoding: String.Encoding.utf8)!)) }
            else { response([]) }
        }
    }
    
    /** Returns an array of recent videos from an associated Channel ID */
    class func sub (_ subID:String, _ response:@escaping ([Video])->())
    {
        Network.GET("https://custom_backend_test.com/channel?c=\(subID)")
        {
            (code, data) -> () in
            
            if (code == 200) { response(self.parse(String(data: data!, encoding: String.Encoding.utf8)!)) }
            else { response([]) }
        }
    }
    
    /** Returns an array of recent videos from an array of Channel IDs */
    class func subs (_ subs:[String], _ response:@escaping ([Video])->())
    {
        let temp = subs.joined(separator: ",")
        
        Network.GET("https://custom_backend_test.com/now?c=\(temp)")
        {
            (code, data) -> () in
                
            if (code == 200) { response(self.parse(String(data: data!, encoding: String.Encoding.utf8)!)) }
            else { response([]) }
        }
    }
    
    /** Returns a tuple with urls associated with a Channel ID's: Official Name and Thumbnail */
    class func channelData (_ ID:String, _ response:@escaping (String, String)->())
    {
        Network.GET("https://custom_backend_test.com/chInfo?c=\(ID)")
        {
            (code, data) -> () in
            
            if (code == 200)
            {
                let output = String(data: data!, encoding: String.Encoding.utf8)!.components(separatedBy: "///:///")
                response(output[0], output[1])
            }
        }
    }
    
    fileprivate class func parse (_ input:String) -> [Video]
    {
        var output:[Video] = [], count = 0
        let tempArray = input.components(separatedBy: "///:///")
        while (count < tempArray.count - 7)
        {
            output.append(Video(title:tempArray[count], thumbnail:tempArray[count+1], time: tempArray[count+2], views:"\(tempArray[count+3]) views", url: tempArray[count+4], channelName:tempArray[count+5], channelID:tempArray[count+6]))
            
            count += 7
        }
        
        return output
    }
    
    /** Returns a video's ID from a complete youtube URL. Example: "https://www.youtube.com/watch?v=jNQXAC9IVRw" returns "jNQXAC9IVRw" */
    class func videoID (_ url:URL) -> String { return url.absoluteString.components(separatedBy: "v=").last! }
    
    /** Returns a video's ID from a complete youtube URL. Example: "https://www.youtube.com/watch?v=jNQXAC9IVRw" returns "jNQXAC9IVRw" */
    class func videoID (_ url:String) -> String { return url.components(separatedBy: "v=").last! }
}

final class Network
{
    class func GET (_ url: String, _ response:@escaping (Int?, Data?)->())
    {
        URLSession.shared.dataTask(with: URL(string: url)!, completionHandler: {
                (data, res, err) -> Void in
                
                response(((res as? HTTPURLResponse)?.statusCode), data)
            })            
.resume()
    }
}

