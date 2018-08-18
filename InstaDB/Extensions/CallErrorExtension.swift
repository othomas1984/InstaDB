//
//  CallErrorExtension.swift
//  InstaDB
//
//  Created by Owen Thomas on 8/18/18.
//  Copyright © 2018 SwiftCoders. All rights reserved.
//

import SwiftyDropbox

extension CallError {
  var errorDescription: String {
    switch self as CallError {
    case .accessError:
      return("Access Denied")
    case .authError:
      return("Authentication Error")
    case .badInputError:
      return("Bad Input")
    case .clientError:
      return("Client Error")
    case .httpError:
      return("Web Error")
    case .internalServerError:
      return("Server Error")
    case .rateLimitError:
      return("Exceeded Rate Limit")
    case .routeError:
      return("Path does not exist")
    }
  }
}
