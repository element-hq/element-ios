// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import CryptoKit

struct VerificationRequiredBannerChecker {
    func canShowBanner(for session: MXSession) -> Bool {
        guard let userID = session.myUserId,
              let serverName = MXTools.serverName(inMatrixIdentifier: userID),
              let data = serverName.components(separatedBy: ".").suffix(2).joined(separator: ".").data(using: .utf8) else {
            return true
        }
        
        let hash = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
        return hash != "9e6d1ca3e739dd3f879b8046af783402a34d247f879dfa1b531edbd56a56c1a6"
    }
}
