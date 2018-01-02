![image](https://github.com/nextseto/Players-iOS/blob/master/assets/banner.png)

[![GitHub license](https://img.shields.io/badge/license-MIT-blue.svg)](https://raw.githubusercontent.com/nextseto/Players-iOS/master/LICENSE)

Players is an iOS application written in Swift that communicates with a custom backend Players-Cloud to get video information and metadata from Youtube.

## Purpose

#### Introduction

I love watching videos in my spare time. Whether its watching TV shows on my TiVo or online via Youtube/Twitch. When I first got my iPod Touch in 2009, I religiously used the built in Youtube app to watch Gaming Let's Plays and other content. When Apple removed the Youtube app in iOS 6, I tried to find alternatives, however, as time went on these apps got bloated and I eventually got frustrated. I spent more time closing the built in popup ads and "Rate me!" dialogues than actually enjoying the purpose of the app, watching my favorite youtube channels.

I was just so fed up with other apps that I took it to myself to make something to satisfy my hunger of watching great content on Youtube.

#### Development Requirements
<<<<<<< HEAD

I made a list of things I wanted in the application:

##### Front-End: iOS Application called "Players"

- Swift: Apple's latest programming language

- UICollectionView: This type of view paradigm is ideal to show the metadata for a given video

- iPhone / iPad Support: Be able to support all iOS devices. Must support most screen sizes

- Easily interface to the backend: Simple GET requests and body parameters for backend communication

##### Back-End: nodeJS web application and REST service called "ytn-cloud"

- nodeJS: A simple lightweight server environment to quickly get up and running

- express: To build some webpages and the REST API part of the service

- async: Performance win using Async.each(...)

- timsort: Performance win using a battle-tested fast sorting algorithm

- node-ytdl: An abstraction over Youtube to access metadata for YouTube information

=======

- Swift: Apple's latest programming language

- Core Data/UserDefaults: Stores data for subscriptions and cached videos

- UICollectionView: This type of view paradigm is ideal to show the metadata for a given video

- iPhone / iPad Support: Be able to support all iOS devices

>>>>>>> v2.0
#### Roadmap

Now, I wrote this in 2014 and I've been slowly working on it to improve its performance and reliability on both the front/back-end side. With the front-end, I had to update the source to conform to the changes to the Swift language. With the back-end, I had to try different package and javascript techniques to shave milliseconds off the processing/response time.

<<<<<<< HEAD
#### Todo list for future versions:
- Use Core Data instead of NSUserDefaults to hold application data

- Improve UICollectionView to be optimized for iPad

- Fully support URLSession with it's delegate methods

- Implement a dedicated 'Channel' View Controller

#### :)

It's been a long road, but 1.x is finally done. I'm proud of what is currently on GitHub.
=======
- [ ] Time Stamps in Videos
- [ ] Detecting and opening links for Channel URLs
- [ ] Full details for cached content
- [ ] Add Placeholders for empty View Controllers
- [ ] Non-Hacky Backgroud Content Playback
- [ ] Now Playing Screen Implementation: Look Screen & Control Center
- [ ] Details for Channels
- [ ] More Options for Searching Videos
- [ ] Support iCloud Sync for Backing Up Subscriptions
- [ ] Support Playlists
- [ ] Twitch-App Style In-App Background Video
- [ ] Support additional Youtube categories: Trending, Private, etc
- [ ] Support additional video provides: Twitch, etc 

#### :)

It's been a long road, but it is finally done. I'm proud of what is currently on GitHub.
>>>>>>> v2.0

Thank you to everyone who has helped me and this project along the way. (Friends, family, reddit testers!!)

## Requirements

- 10.13+ High Sierra
- iOS 11+
- Xcode 9.2 (with Swift 4 support)

## License

All source code in Players-iOS is released under the MIT license. See LICENSE for details.