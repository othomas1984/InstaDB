//
//  FileService.swift
//  InstaDB
//
//  Created by Owen Thomas on 8/17/18.
//  Copyright © 2018 SwiftCoders. All rights reserved.
//

import Foundation
import SwiftyDropbox

class FileService {
  enum AuthState {
    case authenticated
    case unauthenticated
  }
  
  var authState: AuthState {
    return client == nil ? .unauthenticated : .authenticated
  }
  
  typealias Handle = Int
  private var authChangeHandles = [Int: (AuthState) -> Void]()
  private var client: DropboxClient? {
    return DropboxClientsManager.authorizedClient
  }
  
  @objc private func authSuccess() {
    notifyListeners()
  }
  
  @objc private func authCancel() {
    signOut()
  }
  
  @objc private func authError(_ notification: Notification) {
    signOut()
  }
  
  init() {
    listenForAuthChanges()
  }
  
  deinit {
    NotificationCenter.default.removeObserver(self)
  }
  
  func signOut() {
    DropboxClientsManager.unlinkClients()
    notifyListeners()
  }
  
  func listenForAuthChanges(_ listener: @escaping (AuthState) -> Void) -> Handle {
    let maxAuthHandle = authChangeHandles.keys.max() ?? 1
    let nextAuthHandle = maxAuthHandle + 1
    authChangeHandles[nextAuthHandle] = listener
    return nextAuthHandle
  }
  
  func remove(handle: Handle) {
    authChangeHandles[handle] = nil
  }
  
  private func listenForAuthChanges() {
    NotificationCenter.default.addObserver(self, selector: #selector(authSuccess), name: .dropboxAuthSuccess, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(authCancel), name: .dropboxAuthCancel, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(authError(_:)), name: .dropboxAuthError, object: nil)
  }
  
  private func notifyListeners() {
    authChangeHandles.forEach { $0.value(authState) }
  }
}
