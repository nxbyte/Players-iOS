![image](https://github.com/nextseto/ytn-iOS/blob/master/assets/header-ytn-ios.png)

[![GitHub license](https://img.shields.io/badge/license-MIT-blue.svg)](https://raw.githubusercontent.com/nextseto/Verilog-Projects/master/LICENSE)

Players is an iOS application written in Swift that communicates with a custom backend ytn-cloud to get video information and metadata from Youtube.

## Purpose

#### Introduction

I love watching videos in my spare time. Whether its watching TV shows on my TiVo or online via Youtube. When I first got my iPod Touch in 2009, I religiously used the built in Youtube app. And when Apple deprecated it in iOS 6, I tried to find alternatives like McTube or Tubex. They worked for a while, but as time went on these apps got bloated and I eventually got frustrated. I spent more time closing the built in popup apps and "Rate me!" dialogues than actually enjoying the purpose of the app, watching my favorite youtube channels.

I was just so fed up with other apps that I took it to myself to make something to satisfy my hunger of watching great content on Youtube.

#### Development Requirements
I made a list of things I wanted in the application:

##### Front-End: iOS Application called "Players"
- Swift 1 ~ 2: The latest language for quickly building the app with

- UICollectionView: This type of view paradigm is ideal to show the metadata for a given video

- iPhone / iPad Support: Be able to support all iOS devices. Must support most screen sizes

- Easily interface to the backend: Simple GET requests to a backend for communication


##### Back-End: nodeJS web application and REST service called "ytn-cloud"
- nodeJS: A simple lightweight server environment to quickly get up and running

- Express: To build some webpages and the REST API part of the service

- async: Performance win using Async.each(...)

- timsort: Performance win using a battle-tested fast sorting algorithm

- node-ytdl: An abstraction over Youtube to access metadata for YouTube information


#### Roadmap
Now, I wrote this a year ago and I've been slowly working on it to improve its performance and reliability on both the front/back-end side. With the front-end, I had to update the source to conform to the changes to the Swift language. With the back-end, I had to try different package and javascript techniques to shave milliseconds off the processing/response time.


#### Todo list for 2016:
- Use Core Data instead of NSUserDefaults to hold application data

- Improve UICollectionView to be optimized for iPad

- Fully support NSURLSession with it's delegate methods

- Implement a dedicated 'Channel' View Controller

- Explore porting the back-end to use Swift

#### :)
It's been a long road, but 1.0 is finally done. I'm proud of what is currently on GitHub.

Thank you to everyone who has helped me and this project along the way. (Friends, family, reddit testers!!)

If you're interested, here's the iOS Application and the nodeJS service.

## Requirements

- 10.13+ High Sierra
- iOS 8+
- Xcode 9.2 (with Swift 4 support)

## Notice

As of Players (v1.2), this branch will contain the last version to support the legacy v1.x Cloud Service.

## License

All source code in ytn-iOS (Players) is released under the MIT license. See LICENSE for details.