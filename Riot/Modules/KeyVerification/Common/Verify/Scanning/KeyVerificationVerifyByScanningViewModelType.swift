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

protocol KeyVerificationVerifyByScanningViewModelViewDelegate: class {
    func keyVerificationVerifyByScanningViewModel(_ viewModel: KeyVerificationVerifyByScanningViewModelType, didUpdateViewState viewSate: KeyVerificationVerifyByScanningViewState)
}

protocol KeyVerificationVerifyByScanningViewModelCoordinatorDelegate: class {
    func keyVerificationVerifyByScanningViewModelDidCancel(_ viewModel: KeyVerificationVerifyByScanningViewModelType)
    
    func keyVerificationVerifyByScanningViewModel(_ viewModel: KeyVerificationVerifyByScanningViewModelType, didScanOtherQRCodeData qrCodeData: MXQRCodeData, withTransaction transaction: MXQRCodeTransaction)
    
    func keyVerificationVerifyByScanningViewModel(_ viewModel: KeyVerificationVerifyByScanningViewModelType, qrCodeDidScannedByOtherWithTransaction transaction: MXQRCodeTransaction)
    
    func keyVerificationVerifyByScanningViewModel(_ viewModel: KeyVerificationVerifyByScanningViewModelType, didStartSASVerificationWithTransaction transaction: MXSASTransaction)
}

/// Protocol describing the view model used by `KeyVerificationVerifyByScanningViewController`
protocol KeyVerificationVerifyByScanningViewModelType {
            
    var viewDelegate: KeyVerificationVerifyByScanningViewModelViewDelegate? { get set }
    var coordinatorDelegate: KeyVerificationVerifyByScanningViewModelCoordinatorDelegate? { get set }
    
    func process(viewAction: KeyVerificationVerifyByScanningViewAction)
}
