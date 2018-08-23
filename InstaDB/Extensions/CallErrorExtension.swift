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
    case let .internalServerError(code, message, _):
      return "InternalServerError: \(code): \(message ?? "Unknown")"
    case let .badInputError(message, _):
      return "BadInputError: \(message ?? "Unknown")"
    case let .authError(authError, userMessage, errorSummary, _):
      return "AuthError: \(userMessage ?? "") \(errorSummary ?? "") \(authError)"
    case let .accessError(accessError, userMessage, errorSummary, _):
      return "AccessError: \(userMessage ?? "") \(errorSummary ?? "") \(accessError)"
    case let .rateLimitError(rateLimitError, userMessage, errorSummary, _):
      return "RateLimitError: \(userMessage ?? "") \(errorSummary ?? "") \(rateLimitError)"
    case let .httpError(code, message, _):
      return "HTTPError: \(code ?? 0): \(message ?? "Unknown")"
    case let .clientError(error):
      return "ClientError: \(error?.localizedDescription ?? "Unknown")"
    case let .routeError(boxed, _, errorSummary, _):
      // TODO: Handle other types of route errors eventually
      guard let error = boxed.unboxed as? Files.UploadError else { return "Route Error: Unknown" }
      switch error {
      case let .path(writeFailed):
        switch writeFailed.reason {
        case .insufficientSpace:
          return "Dropbox full. Free some space and try again."
        case .tooManyWriteOperations:
          return "Server busy. Please try again."
        default:
          return "Upload failure (\(errorSummary ?? "unknown_error"))."
        }
      case .other:
        return "Unknown File Upload Error"
      case let .propertiesError(invalidProperties):
        return invalidProperties.description
      }
    }
  }
}
