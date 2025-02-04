// 
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

@available(iOS 15.0, *)
enum PillType: Codable {
    case user(userId: String) /// userId
    case room(roomId: String) /// roomId
    case message(roomId: String, eventId: String) // roomId, eventId
}

@available(iOS 15.0, *)
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
