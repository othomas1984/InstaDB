//
//  NotificationNameExtension.swift
//  InstaDB
//
//  Created by Owen Thomas on 8/17/18.
//  Copyright © 2018 SwiftCoders. All rights reserved.
//

import Foundation

extension Notification.Name {
  static let dropboxAuthSuccess = Notification.Name("dropboxAuthSuccess")
  static let dropboxAuthCancel = Notification.Name("dropboxAuthCancel")
  static let dropboxAuthError = Notification.Name("dropboxAuthError")
}
