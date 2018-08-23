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
    window?.backgroundColor = .white
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
