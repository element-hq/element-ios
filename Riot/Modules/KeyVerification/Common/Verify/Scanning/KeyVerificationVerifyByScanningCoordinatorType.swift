// File created from ScreenTemplate
// $ createScreen.sh Verify KeyVerificationVerifyByScanning
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

protocol KeyVerificationVerifyByScanningCoordinatorDelegate: AnyObject {
    func keyVerificationVerifyByScanningCoordinatorDidCancel(_ coordinator: KeyVerificationVerifyByScanningCoordinatorType)    
    func keyVerificationVerifyByScanningCoordinator(_ coordinator: KeyVerificationVerifyByScanningCoordinatorType, didScanOtherQRCodeData qrCodeData: MXQRCodeData, withTransaction transaction: MXQRCodeTransaction)
    func keyVerificationVerifyByScanningCoordinator(_ coordinator: KeyVerificationVerifyByScanningCoordinatorType, qrCodeDidScannedByOtherWithTransaction transaction: MXQRCodeTransaction)    
    func keyVerificationVerifyByScanningCoordinator(_ coordinator: KeyVerificationVerifyByScanningCoordinatorType, didCompleteWithSASTransaction transaction: MXSASTransaction)
}

/// `KeyVerificationVerifyByScanningCoordinatorType` is a protocol describing a Coordinator that handle key backup setup passphrase navigation flow.
protocol KeyVerificationVerifyByScanningCoordinatorType: Coordinator, Presentable {
    var delegate: KeyVerificationVerifyByScanningCoordinatorDelegate? { get }
}
