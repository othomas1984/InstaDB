//
//  LandingViewModel.swift
//  InstaDB
//
//  Created by Owen Thomas on 8/17/18.
//  Copyright © 2018 SwiftCoders. All rights reserved.
//

import Foundation
import RxSwift

class LandingViewModel {
  private let disposeBag = DisposeBag()
  private let fileService: FileService
  let dropboxButtonTapped: AnyObserver<()>
  let authenticated: Observable<FileService.AuthState>
  
  init(delegate: ViewModelDelegate? = nil, fileService: FileService = FileService()) {
    self.fileService = fileService
    let dropboxButtonTappedSubject = PublishSubject<()>()
    dropboxButtonTapped = dropboxButtonTappedSubject.asObserver()
    let authChange = Observable<FileService.AuthState>.create { observer in
      let handle = fileService.listenForAuthChanges { change in
        observer.onNext(change)
      }
      return Disposables.create {
        fileService.remove(handle: handle)
      }
    }.startWith(fileService.authState).share()
    authenticated = authChange.asObservable()

    dropboxButtonTappedSubject.subscribe { event in
      guard case .next = event else { return }
      
    }.disposed(by: disposeBag)
  }
}