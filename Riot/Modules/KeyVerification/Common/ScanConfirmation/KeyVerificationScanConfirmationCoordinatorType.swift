// File created from ScreenTemplate
// $ createScreen.sh KeyVerification/Common/ScanConfirmation KeyVerificationScanConfirmation
/*
 Copyright 2020 New Vector Ltd
 
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

protocol KeyVerificationScanConfirmationCoordinatorDelegate: AnyObject {
    func keyVerificationScanConfirmationCoordinatorDidComplete(_ coordinator: KeyVerificationScanConfirmationCoordinatorType)
    func keyVerificationScanConfirmationCoordinatorDidCancel(_ coordinator: KeyVerificationScanConfirmationCoordinatorType)
}

/// `KeyVerificationScanConfirmationCoordinatorType` is a protocol describing a Coordinator that handle key backup setup passphrase navigation flow.
protocol KeyVerificationScanConfirmationCoordinatorType: Coordinator, Presentable {
    var delegate: KeyVerificationScanConfirmationCoordinatorDelegate? { get }
}
