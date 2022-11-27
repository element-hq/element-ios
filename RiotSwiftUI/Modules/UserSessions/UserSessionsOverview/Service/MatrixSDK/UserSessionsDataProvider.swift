//
// Copyright 2022 New Vector Ltd
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
import MatrixSDK

class UserSessionsDataProvider: UserSessionsDataProviderProtocol {
    private let session: MXSession
    
    init(session: MXSession) {
        self.session = session
    }
    
    var myDeviceId: String {
        session.myDeviceId
    }
    
    var myUserId: String? {
        session.myUserId
    }
    
    var activeAccounts: [MXKAccount] {
        MXKAccountManager.shared().activeAccounts
    }
    
    func devices(completion: @escaping (MXResponse<[MXDevice]>) -> Void) {
        session.matrixRestClient.devices(completion: completion)
    }
    
    func device(withDeviceId deviceId: String, ofUser userId: String) -> MXDeviceInfo? {
        session.crypto.device(withDeviceId: deviceId, ofUser: userId)
    }
    
    func verificationState(for deviceInfo: MXDeviceInfo?) -> UserSessionInfo.VerificationState {
        guard let deviceInfo = deviceInfo else {
            return .permanentlyUnverified
        }

        guard session.crypto?.crossSigning.canCrossSign == true else {
            return deviceInfo.deviceId == session.myDeviceId ? .unverified : .unknown
        }
        
        return deviceInfo.trustLevel.isVerified ? .verified : .unverified
    }
    
    func accountData(for eventType: String) -> [AnyHashable: Any]? {
        session.accountData.accountData(forEventType: eventType)
    }

    func qrLoginAvailable() async throws -> Bool {
        let service = QRLoginService(client: session.matrixRestClient,
                                     mode: .authenticated)
        return try await service.isServiceAvailable()
    }
}
