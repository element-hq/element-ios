// 
// Copyright 2023 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation

@available (iOS 15.0, *)
enum PillType: Codable {
    case user(userId: String) /// userId
    case room(roomId: String) /// roomId
    case message(roomId: String, eventId: String) // roomId, eventId
}

@available (iOS 15.0, *)
extension PillType {
    private static var regexPermalinkTarget: NSRegularExpression? = {
        let clientBaseUrl = BuildSettings.clientPermalinkBaseUrl ?? kMXMatrixDotToUrl
        let pattern = #"(?:\#(clientBaseUrl)|\#(kMXMatrixDotToUrl))/#/(?:(?:room|user)/)?((?:@|!|#)[^@!#/?\s]*)/?((?:\$)[^\$/?\s]*)?"#
        return try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
    }()
    
    static func from(url: URL) -> PillType? {
        guard let regex = regexPermalinkTarget else {
            return nil
        }
        
        var link = url.absoluteString
        // we need to remove percent encoding (it's possible that it has been encoded multiple times)
        while let cleaned = link.removingPercentEncoding, cleaned != link {
            link = cleaned
        }
        
        let pills = regex.matches(in: link, options: [], range: NSRange(link.startIndex..., in: link))
            .map { result -> [String]? in
                guard result.numberOfRanges > 1 else { return nil }
                return (1..<result.numberOfRanges)
                    .map { Range(result.range(at: $0), in: link) }
                    .compactMap { $0 }
                    .map { String(link[$0]).removingPercentEncoding }
                    .compactMap { $0 }
                
            }
            .compactMap { matrixIds -> PillType? in
                guard let matrixIds, !matrixIds.isEmpty else {
                    return nil
                }
                switch matrixIds[0].first {
                case "@":
                    return .user(userId: matrixIds[0])
                case "!", "#":
                    if matrixIds.count > 1 {
                        if matrixIds[1].starts(with: "$") {
                            return .message(roomId: matrixIds[0], eventId: matrixIds[1])
                        }
                    }                    
                    return .room(roomId: matrixIds[0])
                default:
                    return nil
                }
            }

        return pills.first
    }
}
