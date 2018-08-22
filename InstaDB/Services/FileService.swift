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
  typealias Handle = Int
  typealias Path = String
  typealias Progress = Double
  
  static func setup() {
    DropboxClientsManager.setupWithAppKey("kv804kipmgbpxnx")
  }
  
  private static var client: DropboxClient? {
    return DropboxClientsManager.authorizedClient
  }
  
  // MARK: - File Manipulation
  // TODO: Switch to NSCache for better caching
  private static var fetchedFiles = [Path: Data]()
  private static var fetchedThumbnails = [Path: Data]()
  
  func fetchFileList(path: Path, completion: @escaping ([Image], String?) -> Void) {
    FileService.client?.files.listFolder(path: path).response { result, error in
      if let error = error {
        completion([], error.errorDescription)
        return
      }
      let images = result?.entries.map { Image(name: $0.name, path: $0.pathLower) } ?? []
      completion(images, nil)
    }
  }
  
  func fetchThumbnail(atPath path: Path, progressHandler: ((Progress) -> Void)? = nil, completion: @escaping (Data?, String?) -> Void) {
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
    FileService.client?.files.getThumbnail(path: path, format: .png, size: .w640h480, mode: .fitoneBestfit).response { response, error in
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
  
  func fetchFile(atPath path: Path, progressHandler: ((Progress) -> Void)? = nil, completion: @escaping (Data?, String?) -> Void) {
    // Return prior fetched thumbnail if available and exit
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
  
  func upload(_ data: Data, toPath path: Path, progressHandler: ((Progress) -> Void)? = nil, completion: ((String?) -> Void)? = nil) {
    updateProgress(path: path, state: .uploading(progress: 0))
    _ = FileService.client?.files.upload(path: path, input: data).response { _, error in
      if let error = error {
        self.updateProgress(path: path, state: .error(error: error.errorDescription))
        self.removeUpload(path: path)
        completion?(error.errorDescription)
        return
      }
      FileService.fetchedFiles[path.lowercased()] = data
      self.updateProgress(path: path, state: .complete)
      self.removeUpload(path: path)
      completion?(nil)
    }.progress { progressData in
      self.updateProgress(path: path, state: .uploading(progress: progressData.fractionCompleted))
      progressHandler?(progressData.fractionCompleted)
    }
  }
  
  func delete(_ path: Path, completion: ((String?) -> Void)? = nil) {
    FileService.client?.files.deleteV2(path: path).response { _, error in
      if let error = error {
        completion?(error.errorDescription)
        return
      }
      FileService.fetchedFiles[path.lowercased()] = nil
      FileService.fetchedThumbnails[path.lowercased()] = nil
      completion?(nil)
    }
  }
  
  // MARK: - Authentication
  enum AuthState {
    case authenticated
    case unauthenticated
  }
  
  static func authenticate(from controller: UIViewController) {
    DropboxClientsManager.authorizeFromController(UIApplication.shared, controller: controller) {
      UIApplication.shared.open($0)
    }
  }
  
  static var authState: AuthState {
    return client == nil ? .unauthenticated : .authenticated
  }
  
  var authState: AuthState {
    return FileService.authState
  }
  
  private static var authChangeHandles = [Handle: (AuthState) -> Void]()

  static func handleDropboxCallback(_ url: URL) {
    guard let result = DropboxClientsManager.handleRedirectURL(url) else { return }
    switch result {
    case .success:
      notifyAuthListeners()
    case .error, .cancel:
      signOut()
    }
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
  
  private static func notifyAuthListeners() {
    authChangeHandles.forEach { $0.value(authState) }
  }

  static func signOut() {
    DropboxClientsManager.unlinkClients()
    notifyAuthListeners()
  }
  
  // MARK: - File Upload Listener
  enum UploadState {
    case uploading(progress: Double)
    case complete
    case error(error: String)
  }

  private static var uploadsInProgress = [Path: UploadState]()
  private static var fileUploadProgressHandles = [Handle: ([Path: UploadState]) -> Void]()

  func listenForFileUploadChanges(_ listener: @escaping ([Path: UploadState]) -> Void) -> Handle {
    let maxAuthHandle = FileService.fileUploadProgressHandles.keys.max() ?? 1
    let nextAuthHandle = maxAuthHandle + 1
    FileService.fileUploadProgressHandles[nextAuthHandle] = listener
    return nextAuthHandle
  }
  
  func removeFileUpload(handle: Handle) {
    FileService.fileUploadProgressHandles[handle] = nil
  }

  private func updateProgress(path: Path, state: UploadState) {
    FileService.uploadsInProgress[path] = state
    notifyFileUploadListeners()
  }
  
  private func removeUpload(path: Path) {
    FileService.uploadsInProgress[path] = nil
    notifyFileUploadListeners()
  }
  
  private func notifyFileUploadListeners() {
    FileService.fileUploadProgressHandles.forEach { $0.value(FileService.uploadsInProgress) }
  }
}
