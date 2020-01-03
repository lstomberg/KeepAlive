//
//  BackgroundTask.swift
//  KeepAlive
//
//  Created by Lucas Stomberg on 12/27/2019.
//  Copyright © 2019 Lucas Stomberg. All rights reserved.
//

import AVFoundation
import UIKit


private func audioPlayer(withFileNamed filename: String, extension ext: String) -> AVAudioPlayer {
    let bundle = Bundle.main.path(forResource: filename, ofType: ext)
    let alertSound = URL(fileURLWithPath: bundle!)
    let player = try! AVAudioPlayer(contentsOf: alertSound)
    player.numberOfLoops = -1
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

    public static let shared: BackgroundTask = BackgroundTask()
    private var audioPlayer: AVAudioPlayer = newSilentAudioPlayer()
    private let avSession: AVAudioSession = AVAudioSession.sharedInstance()

    //
    // MARK: Init
    //

    init() {
        // configure audio session
        let options: AVAudioSession.CategoryOptions = [.defaultToSpeaker, .interruptSpokenAudioAndMixWithOthers, .allowBluetooth, .allowAirPlay]
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
            case .ended:
                start()
                break

            default:
                break
        }
    }

    @objc
    private func willResignActive() {
        // call on every resignActive.  Why?  I don't know.  But it might fix some issues we were seeing.
        UIApplication.shared.beginReceivingRemoteControlEvents()
    }

}

//
// MARK: Public APIs
//

extension BackgroundTask {

    public func start() {
        try? avSession.setActive(true)
        audioPlayer.play()
        NotificationCenter.default.post(name: .BackgroundTaskDidStart, object: nil)
    }

    public func stop() {
        audioPlayer.stop()
        try? avSession.setActive(false)
        NotificationCenter.default.post(name: .BackgroundTaskDidEnd, object: nil)
    }

}
