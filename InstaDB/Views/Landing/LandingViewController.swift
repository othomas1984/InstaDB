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
  
  @IBOutlet weak var spinner: UIActivityIndicatorView!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    model = LandingViewModel()
    handleAuthChange()
  }
  
  @IBAction func dropboxButtonTapped() {
    DropboxClientsManager.authorizeFromController(UIApplication.shared, controller: self) {
      UIApplication.shared.open($0)
    }
  }
  
  private func handleAuthChange() {
    model.authenticated.subscribe { [unowned self] event in
      guard case let .next(state) = event,
      case .authenticated = state else { return }
      self.spinner.startAnimating()
      Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { _ in
        guard let mainVC = UIStoryboard.init(name: "Main", bundle: nil).instantiateInitialViewController(),
          let window = UIApplication.shared.keyWindow else { return }
        self.spinner.stopAnimating()
        UIView.transition(with: window, duration: 0.5, options: [.transitionFlipFromLeft], animations: {
          window.rootViewController = mainVC
        }, completion: nil)
      }
    }.disposed(by: disposeBag)
  }
}
