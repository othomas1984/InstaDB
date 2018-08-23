//
//  AddPhotoViewController.swift
//  InstaDB
//
//  Created by Owen Thomas on 8/18/18.
//  Copyright © 2018 SwiftCoders. All rights reserved.
//

import UIKit

class AddPhotoViewController: UIViewController {
  private var firstLoad = true
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    // Only show image picker on first load
    if firstLoad, UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
      firstLoad = false
      let picker = UIImagePickerController()
      picker.delegate = self
      present(picker, animated: true)
    }
  }
  
  private func upload(_ data: Data) {
    FileService().upload(data, toPath: "/" + timeStampFilename())
  }
  
  private func timeStampFilename() -> String {
    return String(Int(Date().timeIntervalSince1970)) + ".jpg"
  }
}

extension AddPhotoViewController: UIImagePickerControllerDelegate & UINavigationControllerDelegate {
  func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
    dismiss(animated: true) { self.dismiss(animated: false) }
  }
  
  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String: Any]) {
    var data: Data?
    // Use new UIImagePickerControllerImageURL if on iOS 11, otherwise UIImagePickerControllerOriginalImage
    if #available(iOS 11.0, *),
      let imageUrl = info[UIImagePickerControllerImageURL] as? URL,
      let imageData = try? Data(contentsOf: imageUrl) {
      data = imageData
    } else if let image = info[UIImagePickerControllerOriginalImage] as? UIImage,
      let imageData = UIImageJPEGRepresentation(image, 1.0) {
      data = imageData
    }
    data.map { upload($0) }
    dismiss(animated: true) { self.dismiss(animated: false) }
  }
}
