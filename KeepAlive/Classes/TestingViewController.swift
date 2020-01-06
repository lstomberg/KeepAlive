//
//  TestingViewController.swift
//  KeepAlive
//
//  Created by Lucas Stomberg on 12/27/2019.
//  Copyright © 2019 Lucas Stomberg. All rights reserved.
//

import UIKit

class TestingViewController: UIViewController {
    
    @IBOutlet private weak var label: UILabel!
    @IBOutlet private weak var startTaskButton: UIButton!
    @IBOutlet private weak var stopTaskButton: UIButton!
    
    private var timer = Timer()

    //
    // MARK: Initialization
    //
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        sharedInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        sharedInit()
    }

    private func sharedInit() {
        NotificationCenter.default.addObserver(forName: .BackgroundTaskDidStart, object: nil, queue: nil) { [unowned self] _ in
            self.timer.invalidate()
            self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.timerAction), userInfo: nil, repeats: true)
            self.startTaskButton.alpha = 0.5
            self.startTaskButton.isEnabled = false
            self.stopTaskButton.alpha = 1
            self.stopTaskButton.isEnabled = true
        }

        NotificationCenter.default.addObserver(forName: .BackgroundTaskDidEnd, object: nil, queue: nil) { [unowned self] _ in
            self.timer.invalidate()
            self.startTaskButton.alpha = 1
            self.startTaskButton.isEnabled = true
            self.stopTaskButton.alpha = 0.5
            self.stopTaskButton.isEnabled = false
            self.label.text = ""
        }
    }

    //
    // MARK: Button/Timer Callbacks
    //
    @objc
    private func timerAction() {
        let date = Date()
        let calendar = Calendar.current
        let components = (calendar as NSCalendar).components([ .hour, .minute, .second], from: date)
        let hour = components.hour
        let minutes = components.minute
        let seconds = components.second
        
        label.text = "\(hour ?? 0):\(minutes ?? 0):\(seconds ?? 0)"
    }
    
    @IBAction
    private func startBackgroundTask(_ sender: AnyObject) {
        BackgroundTask.shared.start()
    }
    
    @IBAction
    private func stopBackgroundTask(_ sender: AnyObject) {
        BackgroundTask.shared.stop()
    }
}


