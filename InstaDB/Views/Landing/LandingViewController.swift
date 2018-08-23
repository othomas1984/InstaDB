//
//  LandingViewController.swift
//  InstaDB
//
//  Created by Owen Thomas on 8/17/18.
//  Copyright © 2018 SwiftCoders. All rights reserved.
//

import RxCocoa
import RxSwift

class LandingViewController: UIViewController {
  private var disposeBag = DisposeBag()
  var model: LandingViewModel!
  
  @IBOutlet weak var spinner: UIActivityIndicatorView!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    model = LandingViewModel()
    setupAuthChangeBinding()
  }
  
  @IBAction func dropboxButtonTapped() {
    FileService.authenticate(from: self)
  }
  
  private func setupAuthChangeBinding() {
    // On auth change, if authenticated, replace view controller with Image Collection
    model.authenticated.subscribe { [unowned self] event in
      guard case let .next(state) = event,
      case .authenticated = state else { return }
      self.spinner.startAnimating()
      Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { _ in
        guard let navVC = UIStoryboard.init(name: "ImageCollection", bundle: nil)
          .instantiateInitialViewController() as? UINavigationController,
          let imageCollectionVC = navVC.childViewControllers.first as? ImageCollectionViewController,
          let window = UIApplication.shared.keyWindow else { return }
        self.spinner.stopAnimating()
        imageCollectionVC.model = ImageCollectionViewModel()
        UIView.transition(with: window, duration: 0.5, options: [.transitionFlipFromLeft], animations: {
          window.rootViewController = navVC
        }, completion: nil)
      }
    }.disposed(by: disposeBag)
  }
}
