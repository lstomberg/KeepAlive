//
//  AppDelegate.swift
//  KeepAlive
//
//  Created by Lucas Stomberg on 12/27/2019.
//  Copyright © 2019 Lucas Stomberg. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    //
    // MARK: Handle URL
    //
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        BackgroundTask.shared.start()

        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
            let queryItems = components.queryItems else {
                return false
        }

        for item in queryItems {
            if item.name == "returnURL" {
                if let value = item.value,
                    let url = URL(string: value) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
            }

        }

        return true
    }

}

