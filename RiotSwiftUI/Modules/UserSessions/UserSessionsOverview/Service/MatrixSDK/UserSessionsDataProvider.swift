//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
        session.matrixRestClient.devices { [weak self] response in
            switch response {
            case .success(let devices):
                self?.deleteAccountDataIfNeeded(deviceList: devices)
            case .failure:
                break
            }
            
            completion(response)
        }
    }
    
    func device(withDeviceId deviceId: String, ofUser userId: String) -> MXDeviceInfo? {
        session.crypto.device(withDeviceId: deviceId, ofUser: userId)
    }
    
    func verificationState(for deviceInfo: MXDeviceInfo?) -> UserSessionInfo.VerificationState {
        guard let deviceInfo = deviceInfo else {
            return .permanentlyUnverified
        }
        
        // When the app is launched offline the cross signing state is "notBootstrapped"
        // In this edge case the verification state returned is `.unknown` since we cannot say more even for the current session.
        guard
            let crossSigning = session.crypto?.crossSigning,
            crossSigning.state.rawValue > MXCrossSigningState.notBootstrapped.rawValue
        else {
            return .unknown
        }
        
        guard crossSigning.canCrossSign else {
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

extension UserSessionsDataProvider {
    private func deleteAccountDataIfNeeded(deviceList: [MXDevice]) {
        let obsoletedDeviceAccountDataKeys = obsoletedDeviceAccountData(deviceList: deviceList,
                                                                        accountDataEvents: session.accountData.allAccountDataEvents())
        
        for accountDataKey in obsoletedDeviceAccountDataKeys {
            session.deleteAccountData(withType: accountDataKey, success: {}, failure: { _ in })
        }
    }
    
    // internal just to facilitate tests
    func obsoletedDeviceAccountData(deviceList: [MXDevice], accountDataEvents: [String: Any]) -> Set<String> {
        let deviceAccountDataKeys = Set(
                accountDataEvents
                .map(\.key)
                .filter { $0.hasPrefix(kMXAccountDataTypeClientInformation) }
        )
        
        let expectedDeviceAccountDataKeys = Set(deviceList.map {
            "\(kMXAccountDataTypeClientInformation).\($0.deviceId)"
        })
        
        return deviceAccountDataKeys.subtracting(expectedDeviceAccountDataKeys)
    }
}
