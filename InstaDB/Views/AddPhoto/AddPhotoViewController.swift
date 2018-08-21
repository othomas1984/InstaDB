//
//  AddPhotoViewController.swift
//  InstaDB
//
//  Created by Owen Thomas on 8/18/18.
//  Copyright © 2018 SwiftCoders. All rights reserved.
//

import Photos
import UIKit

class AddPhotoViewController: UIViewController {
  var firstLoad = true
  override func viewDidLoad() {
    super.viewDidLoad()
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    if firstLoad, UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
      let picker = UIImagePickerController()
      picker.delegate = self
      present(picker, animated: true) { self.firstLoad = false }
    }
  }
  
  private func upload(_ data: Data, forFileName fileName: String) {
    guard let newName = timeStamped(fileName: fileName) else { return }
    FileService().upload(data, toPath: "/" + newName)
  }
  
  private func timeStamped(fileName: String) -> String? {
    guard fileName.contains(".") else { return nil }
    return String(Int(Date().timeIntervalSince1970)) + "_" + fileName
  }
}

extension AddPhotoViewController: UIImagePickerControllerDelegate & UINavigationControllerDelegate {
  func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
    dismiss(animated: true) {
      self.dismiss(animated: false, completion: nil)
    }
  }
  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String: Any]) {
    dismiss(animated: true) {
      self.dismiss(animated: false) {
        if #available(iOS 11.0, *) {
          if let imageUrl = info[UIImagePickerControllerImageURL] as? URL,
            let imageData = try? Data.init(contentsOf: imageUrl) {
            self.upload(imageData, forFileName: imageUrl.lastPathComponent)
          }
        } else {
          if let image = info[UIImagePickerControllerOriginalImage] as? UIImage,
            let imageData = UIImageJPEGRepresentation(image, 1.0) {
            self.upload(imageData, forFileName: "upload.jpg")
          }
        }
      }
    }
  }
}
