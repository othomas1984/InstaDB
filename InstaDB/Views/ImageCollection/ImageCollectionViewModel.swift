//
//  ImageCollectionViewModel.swift
//  InstaDB
//
//  Created by Owen Thomas on 8/18/18.
//  Copyright © 2018 SwiftCoders. All rights reserved.
//

import RxSwift

class ImageCollectionViewModel {
  private let disposeBag = DisposeBag()
  let images: Observable<[Image]>
  let loadImages: AnyObserver<()>
  let fileUploadProgress: Observable<[FileService.Path: FileService.UploadState]>
  let imageSize = BehaviorSubject<CGFloat>(value: 125)
  let imageSizeObserver: AnyObserver<Int>
  let delete: AnyObserver<Image>

  init(_ fileService: FileService = FileService()) {
    // Link observers to publish subjects, which can pass the observed values on as observable sequences
    let reloadImagesSubject = PublishSubject<()>()
    loadImages = reloadImagesSubject.asObserver()
    let imageSizeObserverSubject = PublishSubject<Int>()
    imageSizeObserver = imageSizeObserverSubject.asObserver()
    let deleteSubject = PublishSubject<Image>()
    delete = deleteSubject.asObserver()
    
    // Delete file then call reload images when delete event received
    deleteSubject.subscribe { event in
      guard case let .next(image) = event, let path = image.path else { return }
      fileService.delete(path) { _ in
        reloadImagesSubject.onNext(())
      }
    }.disposed(by: disposeBag)

    // Create observable which will send events any time any uploading file has a state change
    fileUploadProgress = Observable<[FileService.Path: FileService.UploadState]>.create { observer in
      let handle = fileService.listenForFileUploadChanges { changes in
        changes.forEach { change in
          if case .complete = change.value {
            reloadImagesSubject.onNext(())
          }
        }
        observer.onNext(changes)
      }
      return Disposables.create {
        fileService.removeFileUpload(handle: handle)
      }
    }
    
    // Create an observable will fetch an updated file list any time reload images events are sent
    let newImages = reloadImagesSubject.map { _ in
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
    }.merge().share()
    
    // Create an observable which will update the image list any time either new image events are sent,
    // or the image size change event is sent
    images = Observable.combineLatest(newImages, imageSizeObserverSubject).map { images, _ in images }
    
    // Listen for image size toggle changes and update the target pixel size for images on next reload
    imageSizeObserverSubject.subscribe { [unowned self] event in
      guard case let .next(value) = event else { return }
      self.imageSize.onNext(CGFloat((value + 1) * 125))
    }.disposed(by: disposeBag)
  }
}
