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
  }
}

extension ImageCollectionViewController: UICollectionViewDelegateFlowLayout {
  var numberOfItemsPerRow: CGFloat { return 3 }
  var itemSpacing: CGFloat { return 8 }
  func collectionView(_ collectionView: UICollectionView,
                      layout collectionViewLayout: UICollectionViewLayout,
                      sizeForItemAt indexPath: IndexPath) -> CGSize {
    let size = (view.bounds.width - itemSpacing * (numberOfItemsPerRow + 1)) / numberOfItemsPerRow
    return CGSize(width: size, height: size)
  }
  func collectionView(_ collectionView: UICollectionView,
                      layout collectionViewLayout: UICollectionViewLayout,
                      insetForSectionAt section: Int) -> UIEdgeInsets {
    return UIEdgeInsets(top: itemSpacing, left: itemSpacing, bottom: itemSpacing, right: itemSpacing)
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
