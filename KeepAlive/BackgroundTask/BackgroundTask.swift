//
//  BackgroundTask.swift
//  KeepAlive
//
//  Created by Lucas Stomberg on 12/27/2019.
//  Copyright © 2019 Lucas Stomberg. All rights reserved.
//

import AVFoundation
import UIKit
import MediaPlayer


private func audioPlayer(withFileNamed filename: String, extension ext: String) -> AVAudioPlayer {
    let bundle = Bundle.main.path(forResource: filename, ofType: ext)
    let fileURL = URL(fileURLWithPath: bundle!)
    let player = try! AVAudioPlayer(contentsOf: fileURL)
    return player
}

private func newSilentAudioPlayer() -> AVAudioPlayer {
    return audioPlayer(withFileNamed: "blank", extension: "wav")
}

public extension NSNotification.Name {
    static let BackgroundTaskDidStart: NSNotification.Name = Self(rawValue: "BackgroundTaskDidStart")
    static let BackgroundTaskDidEnd: NSNotification.Name = Self(rawValue: "BackgroundTaskDidEnd")
}


public class BackgroundTask {

    //
    // MARK: variables
    //

    public static let shared = BackgroundTask()
    private var audioPlayer = newSilentAudioPlayer()
    private let avSession = AVAudioSession.sharedInstance()
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid {
        didSet { UIApplication.shared.endBackgroundTask(oldValue) }
    }
    private let remoteCommandCenter = MPRemoteCommandCenter.shared()

    // debug timer
//    var timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
//        print(UIApplication.shared.backgroundTimeRemaining)
//    }

    //
    // MARK: Init
    //

    init() {

        // configure audio session
        let options: AVAudioSession.CategoryOptions = [.mixWithOthers, .allowAirPlay, .allowBluetooth]
        try? avSession.setCategory(.playback, options: options)

        // configure notifications
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleInterruption),
                                               name: AVAudioSession.interruptionNotification,
                                               object:nil)

       // => App resigning active
       NotificationCenter.default.addObserver(self,
                                              selector: #selector(willResignActive),
                                              name: UIApplication.willResignActiveNotification,
                                              object: nil)
    }

    //
    // MARK: Audio Interruption callback
    //

    @objc
    private func handleInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
            let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
            let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
                return
        }

        switch type {
        case .began:
            backgroundTask = .invalid
        case .ended:
            startBackgroundTask()
        @unknown default:
            fatalError()
        }
    }

    @objc
    private func willResignActive() {
        enableRemoteCommands()
    }

    private func enableRemoteCommands() {
        UIApplication.shared.beginReceivingRemoteControlEvents()
    }

    private func updateNowPlaying() {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        var nowPlayingInfo = [String: Any]()
        let image = UIImage()
        let artwork = MPMediaItemArtwork(boundsSize: image.size, requestHandler: {  (_) -> UIImage in
            return image
        })

        nowPlayingInfo[MPMediaItemPropertyTitle] = "KeepAlive"
        nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = "Unknown"
        nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = 1000.00

        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }

    private func startBackgroundTask() {
        // active = true ensures we get interrupted and can play audio if necessary to stay alive
        try? self.avSession.setActive(true)
        self.enableRemoteCommands()
        self.updateNowPlaying()
        self.audioPlayer.play()
        backgroundTask = UIApplication.shared.beginBackgroundTask { [unowned self] in
            print("Background task expiring")
            self.startBackgroundTask()
        }
    }

}


//
// MARK: Public APIs
//

extension BackgroundTask {

    public func start() {
        startBackgroundTask()
        NotificationCenter.default.post(name: .BackgroundTaskDidStart, object: nil)
    }

    public func stop() {
//        try? self.avSession.setActive(false)
        NotificationCenter.default.post(name: .BackgroundTaskDidEnd, object: nil)
    }

}
