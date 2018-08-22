//
//  AppDelegate.swift
//  InstaDB
//
//  Created by Owen Thomas on 8/17/18.
//  Copyright © 2018 SwiftCoders. All rights reserved.
//

import SwiftyDropbox
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

  var window: UIWindow?

  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
    window?.backgroundColor = .white
    setupDropbox()
    return true
  }

  // swiftlint:disable:next identifier_name
  func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey: Any] = [:]) -> Bool {
    handleDropboxCallback(url)
    return true
  }

  private func setupDropbox() {
    DropboxClientsManager.setupWithAppKey("kv804kipmgbpxnx")
  }
  
  private func handleDropboxCallback(_ url: URL) {
    guard let result = DropboxClientsManager.handleRedirectURL(url) else { return }
    switch result {
    case .success:
      NotificationCenter.default.post(name: Notification.Name.dropboxAuthSuccess, object: nil)
    case .cancel:
      NotificationCenter.default.post(name: Notification.Name.dropboxAuthCancel, object: nil)
    case let .error(_, description):
      NotificationCenter.default.post(name: Notification.Name.dropboxAuthError, object: nil, userInfo: ["description": description])
    }
  }
}
