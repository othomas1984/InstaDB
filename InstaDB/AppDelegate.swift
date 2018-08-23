//
//  AppDelegate.swift
//  InstaDB
//
//  Created by Owen Thomas on 8/17/18.
//  Copyright © 2018 SwiftCoders. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
  var window: UIWindow?

  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?
    ) -> Bool {
    // Set window background to white as it is seen behind some translucent UI elements
    window?.backgroundColor = .white
    
    // Setup FileService with Dropbox API Key
    FileService.setup(apiKey: "kv804kipmgbpxnx")
    return true
  }

  // swiftlint:disable:next identifier_name
  func application(_ app: UIApplication, open url: URL,
                   options: [UIApplicationOpenURLOptionsKey: Any] = [:]) -> Bool {
    FileService.handleDropboxCallback(url)
    return true
  }
}
