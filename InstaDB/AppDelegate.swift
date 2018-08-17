//
//  AppDelegate.swift
//  InstaDB
//
//  Created by Owen Thomas on 8/17/18.
//  Copyright © 2018 SwiftCoders. All rights reserved.
//

import UIKit
import SwiftyDropbox

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

  var window: UIWindow?

  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
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
      print("Success! User is logged into Dropbox.")
    case .cancel:
      print("Authorization flow was manually canceled by user!")
    case .error(_, let description):
      print("Error: \(description)")
    }
  }
}
