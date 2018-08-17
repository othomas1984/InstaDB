//
//  ViewController.swift
//  InstaDB
//
//  Created by Owen Thomas on 8/17/18.
//  Copyright © 2018 SwiftCoders. All rights reserved.
//

import SwiftyDropbox
import UIKit

class ViewController: UIViewController {
  
  override func viewDidLoad() {
    super.viewDidLoad()
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    if let client = DropboxClientsManager.authorizedClient {
      fetchFileList(client)
    } else {
      DropboxClientsManager.authorizeFromController(UIApplication.shared, controller: self) {
        UIApplication.shared.open($0)
      }
    }
  }
  
  private func fetchFileList(_ client: DropboxClient) {
    client.files.listFolder(path: "").response { result, error in
      if let error = error {
        self.handle(error)
        return
      }
      guard let result = result else { return }
      print(result)
    }
  }
  
  private func handle(_ error: CallError<Files.ListFolderError>) {
    switch error as CallError {
    case let .accessError(error, string1, string2, string3):
      print(error, string1 ?? "", string2 ?? "", string3 ?? "")
    case let .authError(error, string1, string2, string3):
      print(error, string1 ?? "", string2 ?? "", string3 ?? "")
    case let .badInputError(string1, string2):
      print(string1 ?? "", string2 ?? "")
    case let .clientError(error):
      print(error ?? "Nil Error")
    case let .httpError(errorCode, string1, string2):
      print(errorCode ?? "Nil error code", string1 ?? "", string2 ?? "")
    case let .internalServerError(errorCode, string1, string2):
      print(errorCode, string1 ?? "", string2 ?? "")
    case let .rateLimitError(error, string1, string2, string3):
      print(error, string1 ?? "", string2 ?? "", string3 ?? "")
    case let .routeError(boxType, string1, string2, string3):
      print(boxType, string1 ?? "", string2 ?? "", string3 ?? "")
    }
  }
  
}
