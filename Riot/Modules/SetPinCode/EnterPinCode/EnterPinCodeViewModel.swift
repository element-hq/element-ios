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
    
    private var currentOperation: MXHTTPOperation?
    private var firstPin: String = ""
    private var currentPin: String = "" {
        didSet {
            self.viewDelegate?.enterPinCodeViewModel(self, didUpdatePlaceholdersCount: currentPin.count)
        }
    }
    
    // MARK: Public

    weak var viewDelegate: EnterPinCodeViewModelViewDelegate?
    weak var coordinatorDelegate: EnterPinCodeViewModelCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(session: MXSession?) {
        self.session = session
    }
    
    deinit {
        self.cancelOperations()
    }
    
    // MARK: - Public
    
    func process(viewAction: EnterPinCodeViewAction) {
        switch viewAction {
        case .digitPressed(let tag):
            self.digitPressed(tag)
        case .cancel:
            self.cancelOperations()
            self.coordinatorDelegate?.enterPinCodeViewModelDidCancel(self)
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
            }
        } else {
            //  a digit tapped
            currentPin += "\(tag)"
            
            if currentPin.count == 4 {
                if firstPin.isEmpty {
                    //  go to next screen
                    firstPin = currentPin
                    currentPin = ""
                    self.update(viewState: .confirmPin)
                } else {
                    //  check first and second pins
                    if firstPin == currentPin {
                        self.coordinatorDelegate?.enterPinCodeViewModel(self, didCompleteWithPin: firstPin)
                    } else {
                        self.update(viewState: .pinsDontMatch(NSError(domain: "", code: -1002, userInfo: nil)))
                        firstPin = ""
                        currentPin = ""
                        self.update(viewState: .enterFirstPin)
                    }
                }
                
                return
            }
        }
    }
    
    private func loadData() {
        self.update(viewState: .enterFirstPin)
    }
    
    private func update(viewState: EnterPinCodeViewState) {
        self.viewDelegate?.enterPinCodeViewModel(self, didUpdateViewState: viewState)
    }
    
    private func cancelOperations() {
        self.currentOperation?.cancel()
    }
}
