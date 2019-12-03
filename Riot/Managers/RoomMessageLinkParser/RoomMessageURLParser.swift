/*
 Copyright 2019 New Vector Ltd
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
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
