/*
 Developer : Warren Seto
 Structs   : VideoEntry, VideoResult, VideoDetail, ChannelDetail, SearchResult
 Classes   : Cloud
 Project   : Players App (v2)
 */

import Foundation

/* Data Structure: Stores Video Information */
struct VideoEntry :Decodable {
    let result    :VideoResult,
        detail    :VideoDetail
}

/* Data Structure: Stores Video Metadata */
struct VideoResult  :Decodable {
    let title       :String,
        thumbnail   :URL,
        videoid     :String,
        channelname :String,
        channelid   :String,
        duration    :String,
        viewcount   :String
}

/* Data Structure: Stores Video Specific Information */
struct VideoDetail  :Decodable {
    let description :String?,
        mp4         :URL?,
        like        :String?,
        dislike     :String?
}

/* Data Structure: Stores Channel Information */
struct ChannelDetail:Decodable {
    let description :String,
        thumbnail   :URL?
}

/* Data Structure: Stores Search Query Response Information */
struct SearchResult :Decodable {
    let nextToken   :String,
        results     :[VideoResult]
}

/* Data Structure: Stores Search Query Information for a Search Request */
struct SearchQuery : CustomStringConvertible {
    
    var query = "",
        nextPageToken = " ",
        option = " "
    
    var description: String {
        return "\(query.addingPercentEncoding(withAllowedCharacters: .alphanumerics)!)/\(nextPageToken.addingPercentEncoding(withAllowedCharacters: .alphanumerics)!)/\(option.addingPercentEncoding(withAllowedCharacters: .alphanumerics)!)"
    }
}

/* API for Accessing Youtube Data with the Cloud Service */
public final class Cloud
{
    /** Returns an array of recent videos from a String of Channel ID Strings seperated by commas */
    class func get(subscriptions:String, results callback: @escaping ([VideoResult]) -> Void) {
        
        URLSession.shared.dataTask(with: URL(string: "https://custom_backend.com/channel/\(subscriptions)")!) { (data, response, error) in
            if data != nil {
                do {
                    return callback(try JSONDecoder().decode([VideoResult].self, from: data!))
                } catch {
                    return callback([])
                }
            } else {
                callback([])
            }
        }.resume()
    }

    /** Return only the full description and MP4 from a given video ID String */
    class func get (video ID:String, withQuality quality:String, details callback: @escaping (VideoDetail?) -> Void) {

        URLSession.shared.dataTask(with: URL(string: "https://custom_backend.com/video/detail/\(ID)/\(quality)")!) { (data, response, error) in
            if data != nil {
                do {
                    return callback(try JSONDecoder().decode(VideoDetail.self, from: data!))
                } catch {
                    return callback(nil)
                }
            } else {
                return callback(nil)
            }
        }.resume()
    }
    
    /** Return the full video information including name, view count, etc and MP4 from a given video ID String */
    class func get (video ID:String, withQuality quality:String, entry callback: @escaping (VideoEntry?) -> Void) {
        
        URLSession.shared.dataTask(with: URL(string: "https://custom_backend.com/video/\(ID)/\(quality)")!) { (data, response, error) in
            if data != nil {
                do {
                    return callback(try JSONDecoder().decode(VideoEntry.self, from: data!))
                } catch {
                    return callback(nil)
                }
            } else {
                callback(nil)
            }
        }.resume()
    }
    
    /** Returns an array of videos from a given Search Query */
    class func get (search payload:SearchQuery, results callback:@escaping (SearchResult)->()) {

        print("https://custom_backend.com/search/\(payload)")
        
        URLSession.shared.dataTask(with: URL(string: "https://custom_backend.com/search/\(payload)")!) { (data, response, error) in
            if data != nil {
                do {
                    return callback(try JSONDecoder().decode(SearchResult.self, from: data!))
                } catch {
                    return callback(SearchResult(nextToken: "", results: []))
                }
            } else {
                return callback(SearchResult(nextToken: "", results: []))
            }
        }.resume()
    }
    
    /** Return only the description, subscriber count, and thumbnail from a given Channel ID String */
    class func get (channel ID:String, details callback:@escaping (ChannelDetail?)->()) {
        
        URLSession.shared.dataTask(with: URL(string: "https://custom_backend.com/channel/detail/\(ID)")!) { (data, response, error) in
            if data != nil {
                do {
                    return callback(try JSONDecoder().decode(ChannelDetail.self, from: data!))
                } catch {
                    return callback(nil)
                }
            } else {
                callback(nil)
            }
        }.resume()
    }
}
