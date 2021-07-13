// File created from ScreenTemplate
// $ createScreen.sh DeviceVerification/Loading DeviceVerificationDataLoading
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

protocol KeyVerificationDataLoadingCoordinatorDelegate: AnyObject {
    func keyVerificationDataLoadingCoordinator(_ coordinator: KeyVerificationDataLoadingCoordinatorType, didLoadUser user: MXUser, device: MXDeviceInfo)
    func keyVerificationDataLoadingCoordinator(_ coordinator: KeyVerificationDataLoadingCoordinatorType, didAcceptKeyVerificationRequestWithTransaction transaction: MXKeyVerificationTransaction)
    func keyVerificationDataLoadingCoordinator(_ coordinator: KeyVerificationDataLoadingCoordinatorType, didAcceptKeyVerificationRequest keyVerificationRequest: MXKeyVerificationRequest)
    func keyVerificationDataLoadingCoordinatorDidCancel(_ coordinator: KeyVerificationDataLoadingCoordinatorType)
}

/// `KeyVerificationDataLoadingCoordinatorType` is a protocol describing a Coordinator that handle key backup setup passphrase navigation flow.
protocol KeyVerificationDataLoadingCoordinatorType: Coordinator, Presentable {
    var delegate: KeyVerificationDataLoadingCoordinatorDelegate? { get }
}
