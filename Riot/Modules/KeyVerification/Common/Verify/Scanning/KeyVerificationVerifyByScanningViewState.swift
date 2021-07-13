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

struct KeyVerificationVerifyByScanningViewData {
    let verificationKind: KeyVerificationKind
    let qrCodeData: Data?
    let showScanAction: Bool
}

/// KeyVerificationVerifyByScanningViewController view state
enum KeyVerificationVerifyByScanningViewState {
    case loading
    case loaded(viewData: KeyVerificationVerifyByScanningViewData)
    case scannedCodeValidated(isValid: Bool)    
    case cancelled(cancelCode: MXTransactionCancelCode, verificationKind: KeyVerificationKind)
    case cancelledByMe(MXTransactionCancelCode)
    case error(Error)
}
