/*
Copyright 2019-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import Foundation

@objc enum RoomMessageURLType: Int {
    case appleDataDetector
    case http
    case dummy
    case unknown
}

/// URL parser for room messages.
@objcMembers
final class RoomMessageURLParser: NSObject {
    
    // MARK: - Constants
    
    private enum Scheme {
        static let appleDataDetector = "x-apple-data-detectors"
        static let http = "http"
        static let https = "https"
    }
    
    private enum Constants {
        static let dummyURL = "#"
    }
    
    // MARK: - Public
    
    func parseURL(_ url: URL) -> RoomMessageURLType {
        
        let roomMessageLink: RoomMessageURLType
        
        if let scheme = url.scheme?.lowercased() {
            switch scheme {
            case Scheme.appleDataDetector:
                roomMessageLink = .appleDataDetector
            case Scheme.http, Scheme.https:
                roomMessageLink = .http
            default:
                roomMessageLink = .unknown
            }
        } else if url.absoluteString == Constants.dummyURL {
            roomMessageLink = .dummy
        } else {
            roomMessageLink = .unknown
        }
        
        return roomMessageLink
    }
}
