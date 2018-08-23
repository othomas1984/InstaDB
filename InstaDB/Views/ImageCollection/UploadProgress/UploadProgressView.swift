//
//  Uploadoutline.swift
//  InstaDB
//
//  Created by Owen Thomas on 8/22/18.
//  Copyright © 2018 SwiftCoders. All rights reserved.
//

import UIKit

class UploadProgressView: UIView {
  private let outline: UIView
  private let mainLabel: UILabel
  private let secondaryLabel: UILabel
  
  init() {
    outline = UIView()
    mainLabel = UILabel()
    secondaryLabel = UILabel()
    super.init(frame: CGRect.zero)

    addSubview(outline)
    outline.addSubview(mainLabel)
    outline.addSubview(secondaryLabel)
    outline.translatesAutoresizingMaskIntoConstraints = false
    mainLabel.translatesAutoresizingMaskIntoConstraints = false
    secondaryLabel.translatesAutoresizingMaskIntoConstraints = false
    
    // Position outline within self
    centerXAnchor.constraint(equalTo: outline.centerXAnchor).isActive = true
    centerYAnchor.constraint(equalTo: outline.centerYAnchor).isActive = true
    heightAnchor.constraint(equalTo: outline.heightAnchor, constant: 6).isActive = true
    widthAnchor.constraint(equalTo: outline.widthAnchor, constant: 8).isActive = true
    
    // Position mainLabel
    mainLabel.leadingAnchor.constraint(equalTo: outline.leadingAnchor, constant: 8).isActive = true
    mainLabel.centerYAnchor.constraint(equalTo: outline.centerYAnchor).isActive = true
    mainLabel.trailingAnchor.constraint(equalTo: secondaryLabel.leadingAnchor, constant: -8).isActive = true
    mainLabel.heightAnchor.constraint(equalTo: outline.heightAnchor, constant: -12).isActive = true
    mainLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

    // Position sublabel
    secondaryLabel.trailingAnchor.constraint(equalTo: outline.trailingAnchor, constant: -8).isActive = true
    secondaryLabel.centerYAnchor.constraint(equalTo: mainLabel.centerYAnchor).isActive = true
    secondaryLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)

    // Style border
    outline.layer.cornerRadius = 10
    
    // Style mainLabel
    mainLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
    mainLabel.textColor = .white
    mainLabel.numberOfLines = 0
    mainLabel.lineBreakMode = .byWordWrapping

    // Style subLabel
    secondaryLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
    secondaryLabel.textColor = .white
  }
  
  var label: String? {
    get { return mainLabel.text }
    set { mainLabel.text = newValue }
  }
  
  var subLabel: String? {
    get { return secondaryLabel.text }
    set { secondaryLabel.text = newValue }
  }
  
  var color: UIColor? {
    get { return outline.layer.backgroundColor.map { UIColor(cgColor: $0) } }
    set { outline.layer.backgroundColor = newValue?.cgColor }
  }
  
  func setHidden(_ hidden: Bool) {
    isHidden = hidden
    alpha = hidden ? 0 : 1
  }

  @available(*, unavailable)
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
