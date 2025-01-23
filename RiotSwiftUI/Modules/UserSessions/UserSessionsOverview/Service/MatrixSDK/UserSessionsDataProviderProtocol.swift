//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixSDK

protocol UserSessionsDataProviderProtocol {
    var myDeviceId: String { get }
    
    var myUserId: String? { get }
    
    var activeAccounts: [MXKAccount] { get }
    
    func devices(completion: @escaping (MXResponse<[MXDevice]>) -> Void)
    
    func device(withDeviceId deviceId: String, ofUser userId: String) -> MXDeviceInfo?
    
    func verificationState(for deviceInfo: MXDeviceInfo?) -> UserSessionInfo.VerificationState
    
    func accountData(for eventType: String) -> [AnyHashable: Any]?

    func qrLoginAvailable() async throws -> Bool
}
