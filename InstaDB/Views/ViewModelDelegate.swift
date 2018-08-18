//
//  ViewModelDelegate.swift
//  InstaDB
//
//  Created by Owen Thomas on 8/17/18.
//  Copyright © 2018 SwiftCoders. All rights reserved.
//

import Foundation

enum ViewModelAction {
  case dismiss
  case show(type: String?, id: String?)
}

protocol ViewModelDelegate: class {
  func send(_ action: ViewModelAction)
}
