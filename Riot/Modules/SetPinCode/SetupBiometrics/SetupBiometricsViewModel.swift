// File created from ScreenTemplate
// $ createScreen.sh SetPinCode/SetupBiometrics SetupBiometrics
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
import LocalAuthentication

final class SetupBiometricsViewModel: SetupBiometricsViewModelType {
    
    // MARK: - Properties
    
    // MARK: Private

    private let session: MXSession?
    private let viewMode: SetPinCoordinatorViewMode
    private let pinCodePreferences: PinCodePreferences
    private let localAuthenticationService: LocalAuthenticationService
    private let biometricsAuthenticationPresenter: BiometricsAuthenticationPresenter
    
    // MARK: Public

    weak var viewDelegate: SetupBiometricsViewModelViewDelegate?
    weak var coordinatorDelegate: SetupBiometricsViewModelCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(session: MXSession?, viewMode: SetPinCoordinatorViewMode, pinCodePreferences: PinCodePreferences) {
        self.session = session
        self.viewMode = viewMode
        self.pinCodePreferences = pinCodePreferences
        self.localAuthenticationService = LocalAuthenticationService(pinCodePreferences: pinCodePreferences)
        self.biometricsAuthenticationPresenter = BiometricsAuthenticationPresenter()
    }
    
    deinit {
        
    }
    
    // MARK: - Public
    
    func localizedBiometricsName() -> String? {
        return pinCodePreferences.localizedBiometricsName()
    }
    
    func biometricsIcon() -> UIImage? {
        return pinCodePreferences.biometricsIcon()
    }
    
    func process(viewAction: SetupBiometricsViewAction) {
        switch viewAction {
        case .loadData:
            loadData()
        case .enableDisableTapped:
            enableDisableBiometrics()
        case .skipOrCancel:
            coordinatorDelegate?.setupBiometricsViewModelDidCancel(self)
        case .unlock:
            unlockWithBiometrics()
        case .cantUnlockedAlertResetAction:
            coordinatorDelegate?.setupBiometricsViewModelDidCompleteWithReset(self, dueToTooManyErrors: false)
        }
    }
    
    // MARK: - Private
    
    private func enableDisableBiometrics() {
        biometricsAuthenticationPresenter.present(with: VectorL10n.biometricsUsageReason) { (response) in
            switch response {
            case .success:
                self.pinCodePreferences.canUseBiometricsToUnlock = nil
                self.pinCodePreferences.resetCounters()
                self.coordinatorDelegate?.setupBiometricsViewModelDidComplete(self)
            case .failure:
                break
            }
        }
    }
    
    private func unlockWithBiometrics() {
        biometricsAuthenticationPresenter.present(with: VectorL10n.biometricsUsageReason) { (response) in
            switch response {
            case .success:
                self.pinCodePreferences.canUseBiometricsToUnlock = nil
                self.pinCodePreferences.resetCounters()
                self.coordinatorDelegate?.setupBiometricsViewModelDidComplete(self)
            case .failure(let error):
                let nsError = error as NSError
                self.pinCodePreferences.numberOfBiometricsFailures += 1
                if self.localAuthenticationService.shouldLogOutUser() {
                    //  biometrics can't be used until further unlock with pin or a new log in
                    self.pinCodePreferences.canUseBiometricsToUnlock = false
                    self.coordinatorDelegate?.setupBiometricsViewModelDidCompleteWithReset(self, dueToTooManyErrors: true)
                } else if nsError.code == LAError.Code.userCancel.rawValue || nsError.code == LAError.Code.userFallback.rawValue {
                    self.userCancelledUnlockWithBiometrics()
                } else {
                    self.update(viewState: .cantUnlocked)
                }
            }
        }
    }
    
    private func userCancelledUnlockWithBiometrics() {
        if pinCodePreferences.isPinSet {
            self.pinCodePreferences.canUseBiometricsToUnlock = false
            //  cascade this cancellation, coordinator should take care of it
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.coordinatorDelegate?.setupBiometricsViewModelDidCancel(self)
            }
        } else {
            //  show an alert to nowhere to go from here
            DispatchQueue.main.async {
                self.update(viewState: .cantUnlocked)
            }
        }
    }
    
    private func loadData() {
        switch viewMode {
        case .setupBiometricsAfterLogin:
            self.update(viewState: .setupAfterLogin)
        case .setupBiometricsFromSettings:
            self.update(viewState: .setupFromSettings)
        case .unlock:
            self.update(viewState: .unlock)
        case .confirmBiometricsToDeactivate:
            self.update(viewState: .confirmToDisable)
        default:
            break
        }
    }
    
    private func update(viewState: SetupBiometricsViewState) {
        self.viewDelegate?.setupBiometricsViewModel(self, didUpdateViewState: viewState)
    }
    
}
