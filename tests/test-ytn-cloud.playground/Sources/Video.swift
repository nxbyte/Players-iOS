//  Warren Seto
//  Video.swift
//  Video Structure for holding values

import Foundation
import UIKit

public struct Video : CustomStringConvertible
{
    let title:String
    let thumbnail:String
    let time:String
    let views:String
    let url:String
    let channelName:String
    let channelID:String
    
    // Implement to support 'CustomStringConvertible'. Basically toString()
    public var description: String {
        return "Title: \(title) \n Thumbnail URL: \(thumbnail) \n Time: \(time) \n # Views: \(views) \n URL: \(url) \n Channel Name: \(channelName) \n Channel ID: \(channelID) \n"
    }
}