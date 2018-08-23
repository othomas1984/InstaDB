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
  let authenticated: Observable<FileService.AuthState>
  
  init(fileService: FileService = FileService()) {
    // Create an observable to send events any time the authentication state changes
    authenticated = Observable<FileService.AuthState>.create { observer in
      let handle = fileService.listenForAuthChanges { change in
        observer.onNext(change)
      }
      return Disposables.create {
        fileService.removeAuth(handle: handle)
      }
    }.startWith(fileService.authState).share()
  }
}
