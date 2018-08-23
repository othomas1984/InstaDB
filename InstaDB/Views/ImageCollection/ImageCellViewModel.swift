//
//  ImageCellViewModel.swift
//  InstaDB
//
//  Created by Owen Thomas on 8/18/18.
//  Copyright © 2018 SwiftCoders. All rights reserved.
//

import RxSwift

class ImageCellViewModel {
  let image: Observable<Data>
  let downloadProgressLabel: Observable<String>
  
  init(_ inputImage: Image, fileService: FileService = FileService()) {
    let downloadProgressSubject = PublishSubject<Double>()
    
    // Convert download progress Doubles into readable labels and create observable to update UI
    downloadProgressLabel = downloadProgressSubject
      .startWith(0)
      .map { "Loading: \(Int($0 * 100))%" }
      .asObservable()
    
    // Create observable to send an event with image Data once the fetchThumbnail method returns
    image = Observable<Data>.create { observer in
      if let path = inputImage.path {
        fileService.fetchThumbnail(atPath: path, progressHandler: downloadProgressSubject.onNext) { imageData, errorDescription in
          if let error = errorDescription {
            // TODO: Show error to user and allow a retry
            print(error)
            return
          }
          guard let imageData = imageData else { return }
          observer.onNext(imageData)
        }
      }
      return Disposables.create()
    }
  }
}
