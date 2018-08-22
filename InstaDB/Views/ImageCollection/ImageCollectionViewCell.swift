//
//  ImageCollectionViewCell.swift
//  InstaDB
//
//  Created by Owen Thomas on 8/18/18.
//  Copyright © 2018 SwiftCoders. All rights reserved.
//

import RxCocoa
import RxSwift
import UIKit

class ImageCollectionViewCell: UICollectionViewCell {
  @IBOutlet weak var label: UILabel!
  @IBOutlet weak var imageView: UIImageView!
  @IBOutlet weak var spinner: UIActivityIndicatorView!
  
  private let disposeBag = DisposeBag()
  private var imageDisposable: Disposable?
  private var nameDisposable: Disposable?
  
  var model: ImageCellViewModel? {
    didSet {
      nameDisposable = model?.downloadProgressLabel.bind(to: label.rx.text)
      imageDisposable = model?.image.bind { [weak self] (imageData: Data) in
        if let image = UIImage(data: imageData) {
          self?.spinner.stopAnimating()
          self?.imageView.image = image
        }
      }
    }
  }
  
  override func prepareForReuse() {
    super.prepareForReuse()
    nameDisposable?.dispose()
    imageDisposable?.dispose()
    model = nil
    imageView.image = nil
    spinner.startAnimating()
  }
}
