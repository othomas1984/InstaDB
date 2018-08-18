//
//  ImageCollectionViewModel.swift
//  InstaDB
//
//  Created by Owen Thomas on 8/18/18.
//  Copyright © 2018 SwiftCoders. All rights reserved.
//

import Foundation
import RxSwift

class ImageCollectionViewModel {
  let images: Observable<[Image]>

  init(_ fileService: FileService = FileService()) {
    images = Observable.create { observer in
      fileService.fetchFileList(path: "") { images, errorDescription in
        if let error = errorDescription {
          print(error)
          return
        }
        observer.onNext(images)
      }
      return Disposables.create()
    }
  }
}
