//
//  ImageCollectionViewController.swift
//  InstaDB
//
//  Created by Owen Thomas on 8/18/18.
//  Copyright © 2018 SwiftCoders. All rights reserved.
//

import RxCocoa
import RxSwift

class ImageCollectionViewController: UIViewController {
  private var uploadProgressIndicators = [FileService.Path: UploadProgressView]()
  private var disposeBag = DisposeBag()
  var model: ImageCollectionViewModel!
  
  @IBOutlet weak var sizeSegmentedControl: UISegmentedControl!
  @IBOutlet weak var stackView: UIStackView!
  @IBOutlet weak var imageCollectionView: UICollectionView!
  @IBOutlet weak var welcomeView: UIView!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setupImageCollectionView()
    setupRefreshControl()
    setupBindings()
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
  
  private func setupImageCollectionView() {
    imageCollectionView.delegate = self
  }
  
  private func setupRefreshControl() {
    let refreshControl = UIRefreshControl()
    imageCollectionView.refreshControl = refreshControl
  }
  
  private func setupBindings() {
    setupImageListChangeBinding(imageCollectionView.refreshControl)
    setupRefreshControlBinding(imageCollectionView.refreshControl)
    setupFileUploadBinding()
    setupSegmentControlBinding()
    setupCollectionViewSelectionBinding()
  }
  
  private func setupImageListChangeBinding(_ refreshControl: UIRefreshControl?) {
    // Provides datasource for collection view
    model.images.bind(to: imageCollectionView.rx
      .items(cellIdentifier: "imageCell")) { _, image, cell in
        if let imageCell = cell as? ImageCollectionViewCell {
          imageCell.model = ImageCellViewModel(image)
        }
    }.disposed(by: disposeBag)
    
    // Show welcome view if no images have been uploaded
    model.images.map { !$0.isEmpty }.startWith(true).bind(to: welcomeView.rx.isHidden).disposed(by: disposeBag)
    
    // Stop refreshing refresh control when images load
    refreshControl.map {
      model.images.map { _ in false }.bind(to: $0.rx.isRefreshing).disposed(by: disposeBag)
    }
  }
  
  private func setupRefreshControlBinding(_ refreshControl: UIRefreshControl?) {
    // Load images when refresh control is activated
    refreshControl?.rx.controlEvent(.valueChanged).bind(to: model.loadImages).disposed(by: disposeBag)
  }
  
  private func setupFileUploadBinding() {
    // Update file progress view(s) when upload progress changes
    model.fileUploadProgress.bind { [unowned self] uploads in
      self.updateFileUploadProgress(uploads)
    }.disposed(by: disposeBag)
  }
  
  private func setupSegmentControlBinding() {
    // Update image size value when segmented control changed
    sizeSegmentedControl.rx.value.bind(to: model.imageSizeObserver).disposed(by: disposeBag)
  }
  
  private func setupCollectionViewSelectionBinding() {
    // Present alert controller for image deletion when a cell is selected
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
  
  @IBAction func signOutTapped(_ sender: Any) {
    FileService.signOut()
    // Replace current view controller with the landing view
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
    // Return existing progress view if there is one
    if let progressView = uploadProgressIndicators[path] {
      return progressView
      
    // Otherwise generate a new one, save it, and return it
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
    // Filter for views that are no longer contained in the list of file paths being uploaded
    uploadProgressIndicators.filter { !paths.contains($0.key) }.forEach { path, progressView in
      // Remove file path from list so it is no longer updated, but do not remove from view until after
      // delay and animation
      uploadProgressIndicators[path] = nil
      // Delay so user has time to read final status
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
