//
//  ImageCollectionViewController.swift
//  InstaDB
//
//  Created by Owen Thomas on 8/18/18.
//  Copyright © 2018 SwiftCoders. All rights reserved.
//

import RxCocoa
import RxSwift
import UIKit

class ImageCollectionViewController: UIViewController {
  private var uploadProgressIndicators = [FileService.Path: UploadProgressView]()
  private var disposeBag = DisposeBag()
  var model: ImageCollectionViewModel!
  
  @IBOutlet weak var sizeSegmentedControl: UISegmentedControl!
  @IBOutlet weak var stackView: UIStackView!
  @IBOutlet weak var imageCollectionView: UICollectionView!
  
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
    imageCollectionView.rx.modelSelected(Image.self).bind { [unowned self] image in
      let ac = UIAlertController(title: "Delete Image?", message: nil, preferredStyle: .alert)
      ac.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
        self.model.delete.onNext(image)
      })
      let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
      ac.addAction(cancelAction)
      ac.preferredAction = cancelAction
      self.present(ac, animated: true)
    }.disposed(by: disposeBag)
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
    FileService.signOut()
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
  
  private func updateFileUploadProgress(_ uploads: [FileService.Path: FileService.UploadState]) {
    uploads.forEach { path, state in
      let view = getOrGenerateProgressView(for: path)
      update(view, with: path, state: state)
    }
    
    removeStaleProgressViews(currentProgressPaths: uploads.keys.map { $0 })
  }
  
  private func getOrGenerateProgressView(for path: FileService.Path) -> UploadProgressView {
    if let progressView = uploadProgressIndicators[path] {
      return progressView
    } else {
      let progressView = UploadProgressView()
      uploadProgressIndicators[path] = progressView
      progressView.setHidden(true)
      stackView.insertArrangedSubview(progressView, at: stackView.arrangedSubviews.count - 1)
      UIView.animate(withDuration: 0.25) {
        progressView.setHidden(false)
      }
      return progressView
    }
  }
  
  private func update(_ view: UploadProgressView, with path: FileService.Path, state: FileService.UploadState) {
    switch state {
    case let .uploading(progress):
      view.label = "Uploading: \(path)"
      let progress = Int(progress * 100)
      let progressText = progress == 100 ? "Verifying..." : "\(progress)%"
      view.subLabel = progressText
      view.color = #colorLiteral(red: 0.1960784314, green: 0.6235294118, blue: 0.9647058824, alpha: 1)
    case .complete:
      view.label = "Uploading: \(path)"
      view.subLabel = "Complete"
      view.color = #colorLiteral(red: 0.1098039216, green: 0.7333333333, blue: 0.2823529412, alpha: 1)
    case let .error(error):
      view.label = error
      view.subLabel = nil
      view.color = #colorLiteral(red: 0.8745098039, green: 0.09803921569, blue: 0.1294117647, alpha: 1)
    }
  }
  
  private func removeStaleProgressViews(currentProgressPaths paths: [FileService.Path]) {
    uploadProgressIndicators.filter { !paths.contains($0.key) }.forEach { path, progressView in
      uploadProgressIndicators[path] = nil
      Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { _ in
        UIView.animate(withDuration: 0.5, delay: 0, options: [], animations: {
          progressView.setHidden(true)
        }, completion: { _ in
          progressView.removeFromSuperview()
        })
      }
    }
  }
}

extension ImageCollectionViewController: UICollectionViewDelegateFlowLayout {
  private var itemSpacing: CGFloat { return 1 }
  private var insetSpacing: CGFloat { return 0 }
  private var numberOfItemsPerRow: CGFloat {
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
