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
    return FileService.client == nil ? .unauthenticated : .authenticated
  }
  
  typealias Handle = Int
  private static var authChangeHandles = [Handle: (AuthState) -> Void]()
  private static var fileUploadProgressHandles = [Handle: ([String: Double]) -> Void]()
  
  private static var client: DropboxClient? {
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
    notifyAuthListeners()
  }
  
  func listenForFileUploadChanges(_ listener: @escaping ([String: Double]) -> Void) -> Handle {
    let maxAuthHandle = FileService.fileUploadProgressHandles.keys.max() ?? 1
    let nextAuthHandle = maxAuthHandle + 1
    FileService.fileUploadProgressHandles[nextAuthHandle] = listener
    return nextAuthHandle
  }
  
  func listenForAuthChanges(_ listener: @escaping (AuthState) -> Void) -> Handle {
    let maxAuthHandle = FileService.authChangeHandles.keys.max() ?? 1
    let nextAuthHandle = maxAuthHandle + 1
    FileService.authChangeHandles[nextAuthHandle] = listener
    return nextAuthHandle
  }
  
  func removeAuth(handle: Handle) {
    FileService.authChangeHandles[handle] = nil
  }
  
  func removeFileUpload(handle: Handle) {
    FileService.fileUploadProgressHandles[handle] = nil
  }
  
  func fetchFileList(path: String, completion: @escaping ([Image], String?) -> Void) {
    FileService.client?.files.listFolder(path: path).response { result, error in
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
    FileService.client?.files.download(path: path).response { response, error in
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
  
  static var uploads = [String: Double]()
  func updateProgress(path: String, progress: Double) {
    FileService.uploads[path] = progress == 1.0 ? nil : progress
    notifyFileUploadListeners()
  }
  
  func upload(_ data: Data, toPath path: String, progressHandler: ((Double) -> Void)? = nil, completion: ((String?) -> Void)? = nil) {
    // TODO: Return the UploadRequest so it can be cancelled if necessary
    updateProgress(path: path, progress: 0)
    _ = FileService.client?.files.upload(path: path, input: data)
      // TODO: Check documentation to see if Files.FileMetaData in response has something
      // useful on an upload request. If so, do something useful with it.
      .response { _, error in
        // TODO: Post upload errors to FileService.uploads to notify user of upload failures
        if let error = error {
          completion?(error.errorDescription)
          return
        }
        FileService.fetchedFiles[path.lowercased()] = data
        completion?(nil)
      }
    .progress { progressData in
      self.updateProgress(path: path, progress: progressData.fractionCompleted)
      progressHandler?(progressData.fractionCompleted)
    }
  }
  
  func fetchThumbnail(atPath path: String, progressHandler: ((Double) -> Void)? = nil, completion: @escaping (Data?, String?) -> Void) {
    // Return prior fetched thumbnail if available and exit
    if let file = FileService.fetchedThumbnails[path] {
      completion(file, nil)
      return
    }
    // Otherwise return full file if available (via recent upload for example), but continue to
    // download the thumbnail so it's available
    if let file = FileService.fetchedFiles[path] {
      completion(file, nil)
    }
    FileService.client?.files.getThumbnail(path: path, format: .png, size: .w256h256, mode: .fitoneBestfit).response { response, error in
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
    notifyAuthListeners()
  }
  
  @objc private func authCancel() {
    signOut()
  }
  
  @objc private func authError(_ notification: Notification) {
    signOut()
  }
  
  private func notifyAuthListeners() {
    FileService.authChangeHandles.forEach { $0.value(authState) }
  }
  
  private func notifyFileUploadListeners() {
    FileService.fileUploadProgressHandles.forEach { $0.value(FileService.uploads) }
  }
}
