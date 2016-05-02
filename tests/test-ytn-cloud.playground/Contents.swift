//: # test-ytn-cloud
//: ## Test between the ytn-iOS client with the ytn-cloud server

import UIKit
import XCPlayground

XCPlaygroundPage.currentPage.needsIndefiniteExecution = true // Run all async functions
delay(5) { XCPlaygroundPage.currentPage.finishExecution() } // After 15 seconds, stop testing

/* Change to point to a custom ytn-cloud server */
let cloudURL = "https://custom_backend_test.com"


//: Test 1: Check if the server can get the MP4 url of the youtube video

Server.videoURL(cloudURL, videoUrl: "https://www.youtube.com/watch?v=cWQ3NXh5tUE", 360)
{
    (mp4URL) -> () in
    
    let success = mp4URL != ""
    
    print(mp4URL)
}

//: Test 2: Check if the server can retrieve the most recent videos for a given array of channel IDs

Server.subs(cloudURL, subs: ["UCddiUEpeqJcYeBxX1IVBKvQ","UC3XTzVzaHQEd30rQbuvCtTQ", "UCX6b17PVsYBQ0ip5gyeme-Q"])
{
    (array) in
    
    let success = array.count != 0
    
    print(array)
}

//: Test 3: Check if the server can retrieve the most recent videos for a given channel ID

Server.sub(cloudURL, subID: "UCddiUEpeqJcYeBxX1IVBKvQ")
{
    (array) in
    
    let success = array.count != 0
    
    print(array)
}

//: Test 4: Check if the server can retrieve the a list of videos for a given query

Server.search(cloudURL, query: "happy", 0)
{
    (array) in
    
    let success = array.count != 0
    
    print(array)
}

//: Test 5: Check if the server can get channel metadata for a given channel ID

Server.channelData(cloudURL, ID: "UCddiUEpeqJcYeBxX1IVBKvQ")
{
    (array) in
    
    let success = array.0 != "" && array.1 != ""
    
    print(array)
}
