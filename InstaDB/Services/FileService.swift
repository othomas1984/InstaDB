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
  
  /* Initial FileService setup. Must be called before any other methods are used
   - Parameter apiKey: Dropbox API key issued to this app
   */
  static func setup(apiKey: String) {
    DropboxClientsManager.setupWithAppKey(apiKey)
  }
  
  /// Dropbox client used for all file manipulation
  private static var client: DropboxClient? {
    return DropboxClientsManager.authorizedClient
  }
  
  // MARK: - File Manipulation
  // TODO: Switch in-memory dictionary storage to NSCache for persistant caching
  /// Local in-memory store of full sized downloaded files for performance purposes
  private static var fetchedFiles = [Path: Data]()
  
  /// Local in-memory store of thumbnails downloaded files for performance purposes
  private static var fetchedThumbnails = [Path: Data]()
  
  /**
   Fetches a list of files at a given path
   - Parameter path: The path to the folder of files
   - Parameter completion: The block to execute after the request finishes. This block has no return value.
   - Parameter images: An array of images. Will be empty if an error happend.
   - Parameter error: Optional String describing any errors.
   */
  func fetchFileList(path: Path, completion: @escaping (_ images: [Image], _ error: String?) -> Void) {
    FileService.client?.files.listFolder(path: path).response { result, error in
      if let error = error {
        completion([], error.errorDescription)
        return
      }
      let images = result?.entries.map { Image(name: $0.name, path: $0.pathLower) } ?? []
      completion(images, nil)
    }
  }
  
  /**
   Fetches data at a given path
   - Parameter path: The path to the data.
   - Parameter progressHandler: The block to execute each time download progress is updated.
   This block has no return value and takes one parameters: a Progress object. May be left nil.
   - Parameter completion: The block to execute after the request finishes. This block has no return
   value.
   - Parameter data: Optional Data object if fetched.
   - Parameter error: Optional String describing any errors.
   
   - Note: fetchThumbnailFile(atPath:size:progressHandler:completion) will download a smaller thumbnail version of the image.
   */
  func fetchFile(atPath path: Path, progressHandler: ((Progress) -> Void)? = nil,
                 completion: @escaping (_ data: Data?, _ error: String?) -> Void) {
    // Return prior fetched thumbnail if available and exit
    if let file = FileService.fetchedFiles[path] {
      completion(file, nil)
      return
    }
    FileService.client?.files.download(path: path).response { response, error in
      guard error == nil else { completion(nil, error?.errorDescription); return }
      let data = response?.1
      FileService.fetchedFiles[path] = data
      completion(data, nil)
    }
    .progress { progressData in
      progressHandler?(progressData.fractionCompleted)
    }
  }
  
  /**
   Fetches a thumbnail image at a given path
   - Parameter path: The path to the image file
   - Parameter size: The size of the thumbnail to download. Defaults to 640x480
   - Parameter progressHandler: The block to execute each time download progress is updated. This block
   has no return value and takes one parameters: a Progress object. May be left nil.
   - Parameter completion: The block to execute after the request finishes. This block has no return value.
   - Parameter data: Optional Data object if fetched.
   - Parameter error: Optional String describing any errors.
   */
  func fetchThumbnail(atPath path: Path, size: Files.ThumbnailSize = .w640h480,
                      progressHandler: ((Progress) -> Void)? = nil,
                      completion: @escaping (_ data: Data?, _ error: String?) -> Void) {
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
    FileService.client?.files.getThumbnail(path: path, format: .png, size: size, mode: .fitoneBestfit).response { response, error in
      guard error == nil else { completion(nil, error?.errorDescription); return }
      let data = response?.1
      FileService.fetchedThumbnails[path] = data
      completion(data, nil)
    }
    .progress { progressData in
      progressHandler?(progressData.fractionCompleted)
    }
  }

  /**
   Uploads data to a given path
   - Parameter data: The data to upload
   - Parameter path: The path where the data should be stored
   - Parameter progressHandler: The block to execute each time upload progress is updated. This block has
   no return value and takes one parameters: a Progress object. May be left nil.
   - Parameter completion: The block to execute after the upload finishes. This block has no return value
   and takes one parameters: an optional String describing any errors.
   */
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
  
  /**
   Delete an object (file or folder) at a given path
   - Parameter path: The path to delete
   - Parameter completion: The block to execute after the upload finishes. This block has no return value
   and takes one parameters: an optional String describing any errors.
   */
  func delete(_ path: Path, completion: @escaping ((String?) -> Void)) {
    FileService.client?.files.deleteV2(path: path).response { _, error in
      guard error == nil else { completion(error?.errorDescription); return }
      FileService.fetchedFiles[path.lowercased()] = nil
      FileService.fetchedThumbnails[path.lowercased()] = nil
      completion(nil)
    }
  }
  
  // MARK: - Authentication
  /// Dropbox authentication state
  enum AuthState {
    /// Dropbox authenticated
    case authenticated
    /// Dropbox not authenticated
    case unauthenticated
  }
  
  /**
   Launches Dropbox's OAuth authentication
   - Parameter controller: The currently presented controller. This will be used to launch a web view for
   OAuth if the Dropbox app is not installed
   */
  static func authenticate(from controller: UIViewController) {
    DropboxClientsManager.authorizeFromController(UIApplication.shared, controller: controller) {
      UIApplication.shared.open($0)
    }
  }
  
  /// Current authentication state
  static var authState: AuthState {
    return client == nil ? .unauthenticated : .authenticated
  }
  
  /// Current authentication state
  var authState: AuthState {
    return FileService.authState
  }
  
  /// Stores registered blocks to be called when authentication changes happen
  private static var authChangeHandles = [Handle: (AuthState) -> Void]()

  /**
   Handle OAuth callbacks from Dropbox
   - Parameter url: The URL dropbox OAuth used to open this app. Process the URL through
   `DropboxClientsMananger.handleRedirectURL(_:)` to get the authentication result
   */
  static func handleDropboxCallback(_ url: URL) {
    guard let result = DropboxClientsManager.handleRedirectURL(url) else { return }
    switch result {
    case .success:
      notifyAuthListeners()
    case .error, .cancel:
      signOut()
      notifyAuthListeners()
    }
  }

  /**
   Register a block to be called any time `authState` changes
   - Parameter listener: The block to be called. This block has no return value.
   - Parameter state: The current `authState` of the app.
   
   - Returns: A `Handle`. Store this handle and call `removeAuth(handle:)` with it when ready to stop
   being notified of auth changes
   */
  func listenForAuthChanges(_ listener: @escaping (_ state: AuthState) -> Void) -> Handle {
    let maxAuthHandle = FileService.authChangeHandles.keys.max() ?? 1
    let nextAuthHandle = maxAuthHandle + 1
    FileService.authChangeHandles[nextAuthHandle] = listener
    return nextAuthHandle
  }
  
  /**
   Unregister an authentication listener block
   - Parameter handle: The block to be unregistered.
   */
  func removeAuth(handle: Handle) {
    FileService.authChangeHandles[handle] = nil
  }
  
  /**
   Notify all authentication change listeners of the current `authState`
   */
  private static func notifyAuthListeners() {
    authChangeHandles.forEach { $0.value(authState) }
  }

  /**
   Sign out from DropBox
   */
  static func signOut() {
    DropboxClientsManager.unlinkClients()
  }
  
  // MARK: - File Upload Listener
  /// File upload state
  enum UploadState {
    /// Uploading. Includes progress percentage
    case uploading(progress: Progress)
    /// Complete
    case complete
    /// Error. Includes error string
    case error(error: String)
  }

  /// Path and current upload state for all in progress uploads
  private static var uploadsInProgress = [Path: UploadState]()
  /// Stores registered blocks to be called when file upload progress changes happen
  private static var fileUploadProgressHandles = [Handle: ([Path: UploadState]) -> Void]()

  /**
   Register a block to be called any time file upload progress changes
   - Parameter listener: The block to be called. This block has no return value.
   - Parameter uploads: list of all current upload paths and associated upload states
   
   - Returns: A `Handle`. Store this handle and call `removeFileUpload(handle:)` with it when ready to stop
   being notified of file upload states
   */
  func listenForFileUploadChanges(_ listener: @escaping (_ uploads: [Path: UploadState]) -> Void) -> Handle {
    let maxAuthHandle = FileService.fileUploadProgressHandles.keys.max() ?? 1
    let nextAuthHandle = maxAuthHandle + 1
    FileService.fileUploadProgressHandles[nextAuthHandle] = listener
    return nextAuthHandle
  }
  
  /**
   Unregister a file upload progress listener block
   - Parameter handle: The block to be unregistered.
   */
  func removeFileUpload(handle: Handle) {
    FileService.fileUploadProgressHandles[handle] = nil
  }

  /**
   Update state of an uploading file
   - Parameter path: The path to the file being uploaded.
   - Parameter state: The new state of the uploading file
   */
  private func updateProgress(path: Path, state: UploadState) {
    FileService.uploadsInProgress[path] = state
    notifyFileUploadListeners()
  }
  
  /**
   Remove a path from the `uploadsInProgress` list. Listeners will no longer be notified of this path.
   - Parameter path: The path to the file to be removed.
   */
  private func removeUpload(path: Path) {
    FileService.uploadsInProgress[path] = nil
    notifyFileUploadListeners()
  }
  
  /**
   Notify all file upload listeners of the current `uploadsInProgress`
   */
  private func notifyFileUploadListeners() {
    FileService.fileUploadProgressHandles.forEach { $0.value(FileService.uploadsInProgress) }
  }
}
