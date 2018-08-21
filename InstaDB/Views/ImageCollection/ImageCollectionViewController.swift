//
//  ImageCollectionViewController.swift
//  InstaDB
//
//  Created by Owen Thomas on 8/18/18.
//  Copyright © 2018 SwiftCoders. All rights reserved.
//

import RxCocoa
import RxSwift
import SwiftyDropbox
import UIKit

class ImageCollectionViewController: UIViewController {
  var disposeBag = DisposeBag()
  var model: ImageCollectionViewModel!
  
  @IBOutlet weak var sizeSegmentedControl: UISegmentedControl!
  @IBOutlet weak var stackView: UIStackView!
  @IBOutlet weak var imageCollectionView: UICollectionView!
  var uploadProgressIndicators = [String: UIView]()
  override func viewDidLoad() {
    super.viewDidLoad()
    imageCollectionView.delegate = self
    model.images
      .bind(to: imageCollectionView.rx
        .items(cellIdentifier: "imageCell")) { _, image, cell in
          if let imageCell = cell as? ImageCollectionViewCell {
            imageCell.model = ImageCellViewModel(image)
          }
      }.disposed(by: disposeBag)
    let refreshControl = UIRefreshControl()
    imageCollectionView.refreshControl = refreshControl
    model.images.map { _ in false }.bind(to: refreshControl.rx.isRefreshing).disposed(by: disposeBag)
    refreshControl.rx.controlEvent(.valueChanged).bind(to: model.loadImages).disposed(by: disposeBag)
    model.fileUploadProgress.bind { [unowned self] uploads in
      self.updateFileUploadProgress(uploads)
    }.disposed(by: disposeBag)
    sizeSegmentedControl.rx.value.bind(to: model.imageSizeObserver).disposed(by: disposeBag)
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    model.loadImages.onNext(())
  }

  override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
    coordinator.animate(alongsideTransition: nil) { _ in
      self.imageCollectionView.reloadData()
    }
  }
  
  @IBAction func signOutTapped(_ sender: Any) {
    DropboxClientsManager.unlinkClients()
    guard let landingVC = UIStoryboard.init(name: "Landing", bundle: nil).instantiateInitialViewController(),
    let window = UIApplication.shared.keyWindow else { return }
    UIView.transition(with: window, duration: 0.5, options: [.transitionFlipFromLeft], animations: {
      window.rootViewController = landingVC
    }, completion: nil)
  }
  
  @IBAction func addTapped(_ sender: Any) {
    guard let addPhotoVC = UIStoryboard.init(name: "AddPhoto", bundle: nil).instantiateInitialViewController() else { return }
    present(addPhotoVC, animated: false, completion: nil)
  }
  
  // TODO: Refactor progress view into it's own UIView subclass
  private func updateFileUploadProgress(_ uploads: [FileService.Path: FileService.Progress]) {
    for (path, progress) in uploads {
      // Update progress indicator if present
      if let progressView = self.uploadProgressIndicators[path] {
        (progressView.subviews[1] as? UILabel)?.text = "\(Int(progress * 100))%"
        
      // Add progress indicator if not present
      } else {
        let progressView = UIView()
        progressView.translatesAutoresizingMaskIntoConstraints = false
        let uploadLabel = UILabel()
        uploadLabel.translatesAutoresizingMaskIntoConstraints = false
        uploadLabel.text = "Uploading \(path)"
        uploadLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
        uploadLabel.lineBreakMode = .byTruncatingMiddle
        let progressLabel = UILabel()
        progressLabel.text = "\(Int(progress * 100))%"
        progressLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
        progressLabel.translatesAutoresizingMaskIntoConstraints = false
        progressView.addSubview(uploadLabel)
        progressView.addSubview(progressLabel)
        uploadLabel.leadingAnchor.constraint(equalTo: progressView.leadingAnchor, constant: 16).isActive = true
        progressLabel.leadingAnchor.constraint(equalTo: uploadLabel.trailingAnchor, constant: 16).isActive = true
        progressView.trailingAnchor.constraint(equalTo: progressLabel.trailingAnchor, constant: 16).isActive = true
        progressLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        uploadLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        progressLabel.firstBaselineAnchor.constraint(equalTo: uploadLabel.firstBaselineAnchor).isActive = true
        uploadLabel.centerYAnchor.constraint(equalTo: progressView.centerYAnchor).isActive = true
        progressView.heightAnchor.constraint(equalTo: uploadLabel.heightAnchor, constant: 8).isActive = true
        progressView.isHidden = true
        progressView.alpha = 0
        self.uploadProgressIndicators[path] = progressView
        self.stackView.insertArrangedSubview(progressView, at: self.stackView.arrangedSubviews.count - 1)
        UIView.animate(withDuration: 0.25) {
          progressView.alpha = 1
          progressView.isHidden = false
        }
      }
    }
    
    // Remove any progress indicators which are no longer needed
    self.uploadProgressIndicators.forEach { path, progressView in
      if !uploads.keys.contains(path) {
        self.uploadProgressIndicators[path] = nil
        UIView.animate(withDuration: 0.25, animations: {
          progressView.isHidden = true
          progressView.alpha = 0
        }, completion: { _ in
          progressView.removeFromSuperview()
          // TODO: Use the file service to notify when the upload is complete via the completion handler of the
          // upload method. Often even with this 2 second delay the file is not ready on the Dropbox server yet
          Timer.scheduledTimer(withTimeInterval: 2, repeats: false) { _ in
            self.model.loadImages.onNext(())
          }
        })
      }
    }
  }
}

extension ImageCollectionViewController: UICollectionViewDelegateFlowLayout {
  var itemSpacing: CGFloat { return 1 }
  var insetSpacing: CGFloat { return 0 }
  var numberOfItemsPerRow: CGFloat {
    let intendedSize = (try? model.imageSize.value()) ?? 125
    return round(imageCollectionView.frame.width / intendedSize)
  }
  
  func collectionView(_ collectionView: UICollectionView,
                      layout collectionViewLayout: UICollectionViewLayout,
                      sizeForItemAt indexPath: IndexPath) -> CGSize {
    let spaceBetweenImages = itemSpacing * (numberOfItemsPerRow - 1)
    let spaceOutsideImages = insetSpacing * 2
    let size = (collectionView.bounds.width - spaceBetweenImages - spaceOutsideImages) / numberOfItemsPerRow
    let sizeRoundedDown = floor(size)
    return CGSize(width: sizeRoundedDown, height: sizeRoundedDown)
  }
  
  func collectionView(_ collectionView: UICollectionView,
                      layout collectionViewLayout: UICollectionViewLayout,
                      insetForSectionAt section: Int) -> UIEdgeInsets {
    return UIEdgeInsets(top: insetSpacing, left: insetSpacing, bottom: insetSpacing, right: insetSpacing)
  }
  
  func collectionView(_ collectionView: UICollectionView,
                      layout collectionViewLayout: UICollectionViewLayout,
                      minimumLineSpacingForSectionAt section: Int) -> CGFloat {
    return itemSpacing
  }
  
  func collectionView(_ collectionView: UICollectionView,
                      layout collectionViewLayout: UICollectionViewLayout,
                      minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
    return itemSpacing
  }
}
