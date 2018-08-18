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
  
  static var fetchedFiles = [String: Data]()
  static var fetchedThumbnails = [String: Data]()

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
  
  func fetchFileList(path: String, completion: @escaping ([Image], String?) -> Void) {
    client?.files.listFolder(path: path).response { result, error in
      if let error = error {
        completion([], error.errorDescription)
        return
      }
      let images = result?.entries.map { Image(name: $0.name, path: $0.pathLower) } ?? []
      completion(images, nil)
    }
  }
  
  func fetchFile(atPath path: String, progressHandler: ((Double) -> Void)? = nil, completion: @escaping (Data?, String?) -> Void) {
    if let file = FileService.fetchedFiles[path] {
      completion(file, nil)
      return
    }
    client?.files.download(path: path).response { response, error in
      if let error = error {
        completion(nil, error.errorDescription)
        return
      }
      let data = response?.1
      FileService.fetchedFiles[path] = data
      completion(data, nil)
    }
    .progress { progressData in
      progressHandler?(progressData.fractionCompleted)
    }
  }
  
  func fetchThumbnail(atPath path: String, progressHandler: ((Double) -> Void)? = nil, completion: @escaping (Data?, String?) -> Void) {
    if let file = FileService.fetchedThumbnails[path] {
      completion(file, nil)
      return
    }
    client?.files.getThumbnail(path: path, format: .png, size: .w256h256, mode: .fitoneBestfit).response { response, error in
      if let error = error {
        completion(nil, error.errorDescription)
        return
      }
      let data = response?.1
      FileService.fetchedThumbnails[path] = data
      completion(data, nil)
    }
    .progress { progressData in
      progressHandler?(progressData.fractionCompleted)
    }
  }
  
  private func listenForAuthChanges() {
    NotificationCenter.default.addObserver(self, selector: #selector(authSuccess), name: .dropboxAuthSuccess, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(authCancel), name: .dropboxAuthCancel, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(authError(_:)), name: .dropboxAuthError, object: nil)
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
  
  private func notifyListeners() {
    authChangeHandles.forEach { $0.value(authState) }
  }
}
