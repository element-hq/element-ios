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
