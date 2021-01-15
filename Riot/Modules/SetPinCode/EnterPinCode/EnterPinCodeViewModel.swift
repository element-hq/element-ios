// File created from ScreenTemplate
// $ createScreen.sh SetPinCode/EnterPinCode EnterPinCode
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

final class EnterPinCodeViewModel: EnterPinCodeViewModelType {
    
    // MARK: - Properties
    
    // MARK: Private

    private let session: MXSession?
    private var originalViewMode: SetPinCoordinatorViewMode
    private var viewMode: SetPinCoordinatorViewMode
    
    private var initialPin: String = ""
    private var firstPin: String = ""
    private var currentPin: String = "" {
        didSet {
            self.viewDelegate?.enterPinCodeViewModel(self, didUpdatePlaceholdersCount: currentPin.count)
        }
    }
    private var numberOfFailuresDuringEnterPIN: Int = 0
    
    // MARK: Public

    weak var viewDelegate: EnterPinCodeViewModelViewDelegate?
    weak var coordinatorDelegate: EnterPinCodeViewModelCoordinatorDelegate?
    private let pinCodePreferences: PinCodePreferences
    private let localAuthenticationService: LocalAuthenticationService
    
    // MARK: - Setup
    
    init(session: MXSession?, viewMode: SetPinCoordinatorViewMode, pinCodePreferences: PinCodePreferences) {
        self.session = session
        self.originalViewMode = viewMode
        self.viewMode = viewMode
        self.pinCodePreferences = pinCodePreferences
        self.localAuthenticationService = LocalAuthenticationService(pinCodePreferences: pinCodePreferences)
    }
    
    // MARK: - Public
    
    func process(viewAction: EnterPinCodeViewAction) {
        switch viewAction {
        case .loadData:
            self.loadData()
        case .digitPressed(let tag):
            self.digitPressed(tag)
        case .forgotPinPressed:
            self.viewDelegate?.enterPinCodeViewModel(self, didUpdateViewState: .forgotPin)
        case .cancel:
            self.coordinatorDelegate?.enterPinCodeViewModelDidCancel(self)
        case .pinsDontMatchAlertAction:
            //  reset pins
            firstPin.removeAll()
            currentPin.removeAll()
            //  go back to first state
            self.update(viewState: .choosePin)
        case .forgotPinAlertResetAction:
            self.coordinatorDelegate?.enterPinCodeViewModelDidCompleteWithReset(self, dueToTooManyErrors: false)
        case .forgotPinAlertCancelAction:
            //  no-op
            break
        }
    }
    
    // MARK: - Private
    
    private func digitPressed(_ tag: Int) {
        if tag == -1 {
            //  delete tapped
            if currentPin.isEmpty {
                return
            } else {
                currentPin.removeLast()
                
                //  switch to setPin if blocked
                if viewMode == .notAllowedPin {
                    //  clear error UI
                    update(viewState: viewState(for: originalViewMode))
                    //  switch back to original flow
                    viewMode = originalViewMode
                }
            }
        } else {
            //  a digit tapped
            
            //  switch to setPin if blocked
            if viewMode == .notAllowedPin {
                //  clear old pin first
                currentPin.removeAll()
                //  clear error UI
                update(viewState: viewState(for: originalViewMode))
                //  switch back to original flow
                viewMode = originalViewMode
            }
            //  add new digit
            currentPin += String(tag)
            
            if currentPin.count == pinCodePreferences.numberOfDigits {
                switch viewMode {
                case .setPin, .setPinAfterLogin, .setPinAfterRegister:
                    //  choosing pin
                    updateAfterPinSet()
                case .unlock, .confirmPinToDeactivate:
                    //  unlocking
                    if currentPin != pinCodePreferences.pin {
                        //  no match
                        updateAfterUnlockFailed()
                    } else {
                        //  match
                        //  we can use biometrics anymore, if set
                        pinCodePreferences.canUseBiometricsToUnlock = nil
                        pinCodePreferences.resetCounters()
                        //  complete with a little delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            self.coordinatorDelegate?.enterPinCodeViewModelDidComplete(self)
                        }
                    }
                case .changePin:
                    //  unlocking
                    if initialPin.isEmpty && currentPin != pinCodePreferences.pin {
                        //  no match
                        updateAfterUnlockFailed()
                    } else if initialPin.isEmpty {
                        //  match or already unlocked
                        
                            // the user can choose a new Pin code
                            initialPin = currentPin
                            currentPin.removeAll()
                            update(viewState: .choosePin)
                        } else {
                            //  choosing pin
                            updateAfterPinSet()
                        }
                default:
                    break
                }
                return
            }
        }
    }
    
    private func viewState(for mode: SetPinCoordinatorViewMode) -> EnterPinCodeViewState {
        switch mode {
        case .setPin:
            return .choosePin
        case .setPinAfterLogin:
            return .choosePinAfterLogin
        case .setPinAfterRegister:
            return .choosePinAfterRegister
        case .changePin:
            return .changePin
        default:
            return .inactive
        }
    }
    
    private func loadData() {
        switch viewMode {
        case .setPin, .setPinAfterLogin, .setPinAfterRegister:
            update(viewState: viewState(for: viewMode))
            self.viewDelegate?.enterPinCodeViewModel(self, didUpdateCancelButtonHidden: pinCodePreferences.forcePinProtection)
        case .unlock:
            update(viewState: .unlock)
        case .confirmPinToDeactivate:
            update(viewState: .confirmPinToDisable)
        case .inactive:
            update(viewState: .inactive)
        case .changePin:
            update(viewState: .changePin)
        default:
            break
        }
    }
    
    private func update(viewState: EnterPinCodeViewState) {
        self.viewDelegate?.enterPinCodeViewModel(self, didUpdateViewState: viewState)
    }
    
    private func updateAfterUnlockFailed() {
        numberOfFailuresDuringEnterPIN += 1
        pinCodePreferences.numberOfPinFailures += 1
        if viewMode == .unlock && localAuthenticationService.shouldLogOutUser() {
            //  log out user
            self.coordinatorDelegate?.enterPinCodeViewModelDidCompleteWithReset(self, dueToTooManyErrors: true)
            return
        }
        if numberOfFailuresDuringEnterPIN < pinCodePreferences.allowedNumberOfTrialsBeforeAlert {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.viewDelegate?.enterPinCodeViewModel(self, didUpdateViewState: .wrongPin)
                self.currentPin.removeAll()
            }
        } else {
            viewDelegate?.enterPinCodeViewModel(self, didUpdateViewState: .wrongPinTooManyTimes)
            numberOfFailuresDuringEnterPIN = 0
            currentPin.removeAll()
        }
    }
    
    private func updateAfterPinSet() {
        if firstPin.isEmpty {
            //  check if this PIN is allowed
            if pinCodePreferences.notAllowedPINs.contains(currentPin) {
                viewMode = .notAllowedPin
                update(viewState: .notAllowedPin)
                return
            }
            //  go to next screen
            firstPin = currentPin
            currentPin.removeAll()
            update(viewState: .confirmPin)
        } else if firstPin == currentPin { //  check first and second pins        
                //  complete with a little delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.coordinatorDelegate?.enterPinCodeViewModel(self, didCompleteWithPin: self.firstPin)
                }
        } else {
                update(viewState: .pinsDontMatch)
        }
    }
}
