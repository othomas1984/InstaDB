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
  let loadImages: AnyObserver<()>

  init(_ fileService: FileService = FileService()) {
    let reloadImagesSubject = PublishSubject<()>()
    loadImages = reloadImagesSubject.asObserver()
    images = reloadImagesSubject.map { _ in
      Observable<[Image]>.create { observer in
        fileService.fetchFileList(path: "") { images, errorDescription in
          if let error = errorDescription {
            // TODO: Show error to user and allow a retry
            print(error)
            return
          }
          observer.onNext(images)
        }
        return Disposables.create()
      }
    }.merge()
  }
}
