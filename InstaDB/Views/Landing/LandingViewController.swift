//
//  LandingViewController.swift
//  InstaDB
//
//  Created by Owen Thomas on 8/17/18.
//  Copyright © 2018 SwiftCoders. All rights reserved.
//

import RxSwift
import SwiftyDropbox
import UIKit

class LandingViewController: UIViewController {
  var model: LandingViewModel!
  var disposeBag = DisposeBag()
  
  @IBOutlet weak var dropboxButton: UIButton!
  override func viewDidLoad() {
    super.viewDidLoad()
    model = LandingViewModel()
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    handleAuthChange()
  }

  @IBAction func dropboxButtonTapped() {
    attemptDropboxAuth()
  }
  
  private func attemptDropboxAuth() {
    DropboxClientsManager.authorizeFromController(UIApplication.shared, controller: self) {
      UIApplication.shared.open($0)
    }
  }
  
  private func handleAuthChange() {
    model.authenticated.delay(0.2, scheduler: MainScheduler()).subscribe { [unowned self] event in
      guard case let .next(state) = event else { return }
      switch state {
      case .authenticated:
        guard let mainVC = UIStoryboard.init(name: "Main", bundle: nil).instantiateInitialViewController() else { return }
        self.present(mainVC, animated: true, completion: nil)
      case .unauthenticated:
        self.dismiss(animated: true, completion: nil)
      }
    }.disposed(by: disposeBag)
  }
}
