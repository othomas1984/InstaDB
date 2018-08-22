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
  private func updateFileUploadProgress(_ uploads: [FileService.Path: FileService.UploadState]) {
    for (path, state) in uploads {
      // Update progress indicator if present
      let containerView: UIView
      let progressView: UIView
      let uploadLabel: UILabel
      let progressLabel: UILabel

      if let container = self.uploadProgressIndicators[path] {
        containerView = container
        progressView = containerView.subviews[0]
        guard let upload = progressView.subviews[0] as? UILabel,
          let progress = progressView.subviews[1] as? UILabel else { return }
        uploadLabel = upload
        progressLabel = progress
        
      // Add progress indicator if not present
      } else {
        containerView = UIView()
        progressView = UIView()
        containerView.addSubview(progressView)
        containerView.centerXAnchor.constraint(equalTo: progressView.centerXAnchor).isActive = true
        containerView.centerYAnchor.constraint(equalTo: progressView.centerYAnchor).isActive = true
        containerView.heightAnchor.constraint(equalTo: progressView.heightAnchor, constant: 6).isActive = true
        containerView.widthAnchor.constraint(equalTo: progressView.widthAnchor, constant: 8).isActive = true
        progressView.layer.backgroundColor = #colorLiteral(red: 0.1960784314, green: 0.6235294118, blue: 0.9647058824, alpha: 1).cgColor
        
        progressView.layer.cornerRadius = 10
        progressView.translatesAutoresizingMaskIntoConstraints = false
        uploadLabel = UILabel()
        uploadLabel.translatesAutoresizingMaskIntoConstraints = false
        uploadLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
        uploadLabel.textColor = .white
        uploadLabel.lineBreakMode = .byTruncatingMiddle
        progressLabel = UILabel()
        progressLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
        progressLabel.textColor = .white
        progressLabel.translatesAutoresizingMaskIntoConstraints = false
        progressView.addSubview(uploadLabel)
        progressView.addSubview(progressLabel)
        uploadLabel.leadingAnchor.constraint(equalTo: progressView.leadingAnchor, constant: 8).isActive = true
        progressLabel.leadingAnchor.constraint(equalTo: uploadLabel.trailingAnchor, constant: 8).isActive = true
        progressView.trailingAnchor.constraint(equalTo: progressLabel.trailingAnchor, constant: 8).isActive = true
        progressLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        uploadLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        progressLabel.firstBaselineAnchor.constraint(equalTo: uploadLabel.firstBaselineAnchor).isActive = true
        uploadLabel.centerYAnchor.constraint(equalTo: progressView.centerYAnchor).isActive = true
        progressView.heightAnchor.constraint(equalTo: uploadLabel.heightAnchor, constant: 12).isActive = true
        progressView.isHidden = true
        progressView.alpha = 0
        self.uploadProgressIndicators[path] = containerView
        self.stackView.insertArrangedSubview(containerView, at: self.stackView.arrangedSubviews.count - 1)
        UIView.animate(withDuration: 0.25) {
          progressView.alpha = 1
          progressView.isHidden = false
        }
      }
      switch state {
      case let .uploading(progress):
        uploadLabel.text = "Uploading \(path)"
        progressLabel.text = "\(Int(progress * 100))%"
        progressView.layer.backgroundColor = #colorLiteral(red: 0.1960784314, green: 0.6235294118, blue: 0.9647058824, alpha: 1).cgColor
      case .complete:
        uploadLabel.text = "Uploading: \(path)"
        progressLabel.text = "Complete"
        progressView.layer.backgroundColor = #colorLiteral(red: 0.1098039216, green: 0.7333333333, blue: 0.2823529412, alpha: 1).cgColor
        model.loadImages.onNext(())
      case let .error(error):
        uploadLabel.text = error
        uploadLabel.numberOfLines = 0
        uploadLabel.lineBreakMode = .byWordWrapping
        progressLabel.text = nil
        progressView.layer.backgroundColor = #colorLiteral(red: 0.8745098039, green: 0.09803921569, blue: 0.1294117647, alpha: 1).cgColor
      }
    }
    
    // Remove any progress indicators which are no longer needed
    self.uploadProgressIndicators.forEach { path, containerView in
      if !uploads.keys.contains(path) {
        self.uploadProgressIndicators[path] = nil
        Timer.scheduledTimer(withTimeInterval: 2, repeats: false) { _ in
          UIView.animate(withDuration: 0.5, animations: {
            containerView.isHidden = true
            containerView.alpha = 0
          }, completion: { _ in
            containerView.removeFromSuperview()
          })
        }
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
