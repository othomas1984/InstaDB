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
    case let .internalServerError(code, message, requestId):
      return("InternalServerError[\(requestId ?? "Unknown")]: \(code): \(message ?? "Unknown")")
    case let .badInputError(message, requestId):
      return("BadInputError[\(requestId ?? "Unknown")]: \(message ?? "Unknown")")
    case let .authError(authError, userMessage, errorSummary, requestId):
      return("AuthError[\(requestId ?? "Unknown")]: \(userMessage ?? "Unknown") \(errorSummary ?? "Unknown") \(authError)")
    case let .accessError(accessError, userMessage, errorSummary, requestId):
      return("AccessError[\(requestId ?? "Unknown")]: \(userMessage ?? "Unknown") \(errorSummary ?? "Unknown") \(accessError)")
    case let .rateLimitError(rateLimitError, userMessage, errorSummary, requestId):
      return("RateLimitError[\(requestId ?? "Unknown")]: \(userMessage ?? "Unknown") \(errorSummary ?? "Unknown") \(rateLimitError)")
    case let .httpError(code, message, requestId):
      return("HTTPError[\(requestId ?? "Unknown")]: \(code ?? 0): \(message ?? "Unknown")")
    case let .clientError(error):
      return("ClientError: \(error?.localizedDescription ?? "Unknown")")
    case .routeError:
      return("Path does not exist")
    }
  }
}
