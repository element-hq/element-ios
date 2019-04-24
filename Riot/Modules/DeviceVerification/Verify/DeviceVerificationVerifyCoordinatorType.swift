// File created from ScreenTemplate
// $ createScreen.sh DeviceVerification/Verify DeviceVerificationVerify
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

protocol DeviceVerificationVerifyCoordinatorDelegate: class {
    func deviceVerificationVerifyCoordinatorDidComplete(_ coordinator: DeviceVerificationVerifyCoordinatorType)
    func deviceVerificationVerifyCoordinatorDidCancel(_ coordinator: DeviceVerificationVerifyCoordinatorType)
}

/// `DeviceVerificationVerifyCoordinatorType` is a protocol describing a Coordinator that handle key backup setup passphrase navigation flow.
protocol DeviceVerificationVerifyCoordinatorType: Coordinator, Presentable {
    var delegate: DeviceVerificationVerifyCoordinatorDelegate? { get }
}
