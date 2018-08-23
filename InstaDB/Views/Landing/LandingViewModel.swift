//
//  LandingViewModel.swift
//  InstaDB
//
//  Created by Owen Thomas on 8/17/18.
//  Copyright © 2018 SwiftCoders. All rights reserved.
//

import RxSwift

class LandingViewModel {
  private let disposeBag = DisposeBag()
  private let fileService: FileService
  let authenticated: Observable<FileService.AuthState>
  
  init(delegate: ViewModelDelegate? = nil, fileService: FileService = FileService()) {
    self.fileService = fileService
    let authChange = Observable<FileService.AuthState>.create { observer in
      let handle = fileService.listenForAuthChanges { change in
        observer.onNext(change)
      }
      return Disposables.create {
        fileService.removeAuth(handle: handle)
      }
    }.startWith(fileService.authState).share()
    authenticated = authChange.asObservable()
  }
}
