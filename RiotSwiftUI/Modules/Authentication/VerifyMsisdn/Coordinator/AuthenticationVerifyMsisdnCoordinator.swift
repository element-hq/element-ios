//
// Copyright 2021 New Vector Ltd
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

import SwiftUI
import CommonKit
import libPhoneNumber_iOS

struct AuthenticationVerifyMsisdnCoordinatorParameters {
    let registrationWizard: RegistrationWizard
    /// The homeserver that is requesting MSISDN verification.
    let homeserver: AuthenticationState.Homeserver
}

final class AuthenticationVerifyMsisdnCoordinator: Coordinator, Presentable {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let parameters: AuthenticationVerifyMsisdnCoordinatorParameters
    private let authenticationVerifyMsisdnHostingController: VectorHostingController
    private var authenticationVerifyMsisdnViewModel: AuthenticationVerifyMsisdnViewModelProtocol
    
    private var indicatorPresenter: UserIndicatorTypePresenterProtocol
    private var loadingIndicator: UserIndicator?
    
    /// The wizard used to handle the registration flow.
    private var registrationWizard: RegistrationWizard { parameters.registrationWizard }
    
    private var currentTask: Task<Void, Error>? {
        willSet {
            currentTask?.cancel()
        }
    }
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    var callback: (@MainActor (AuthenticationRegistrationStageResult) -> Void)?
    
    // MARK: - Setup
    
    @MainActor init(parameters: AuthenticationVerifyMsisdnCoordinatorParameters) {
        self.parameters = parameters
        
        let viewModel = AuthenticationVerifyMsisdnViewModel(homeserver: parameters.homeserver.viewData)
        let view = AuthenticationVerifyMsisdnScreen(viewModel: viewModel.context)
        authenticationVerifyMsisdnViewModel = viewModel
        authenticationVerifyMsisdnHostingController = VectorHostingController(rootView: view)
        authenticationVerifyMsisdnHostingController.vc_removeBackTitle()
        authenticationVerifyMsisdnHostingController.enableNavigationBarScrollEdgeAppearance = true
        
        indicatorPresenter = UserIndicatorTypePresenter(presentingViewController: authenticationVerifyMsisdnHostingController)
    }
    
    // MARK: - Public
    
    func start() {
        MXLog.debug("[AuthenticationVerifyMsisdnCoordinator] did start.")
        Task { await setupViewModel() }
    }
    
    func toPresentable() -> UIViewController {
        return self.authenticationVerifyMsisdnHostingController
    }
    
    // MARK: - Private

    /// Attempts to extract the country code from a given phone number. Throws `RegistrationError.invalidPhoneNumber` if cannot.
    private func countryCodeFromPhoneNumber(_ phoneNumber: String) throws -> String {
        do {
            let phoneNumber = try NBPhoneNumberUtil.sharedInstance().parse(phoneNumber,
                                                                           defaultRegion: nil)
            guard let countryCode = phoneNumber.countryCode else {
                throw RegistrationError.invalidPhoneNumber
            }
            return String(countryCode.intValue)
        } catch {
            throw RegistrationError.invalidPhoneNumber
        }
    }
    
    /// Set up the view model. This method is extracted from `start()` so it can run on the `MainActor`.
    @MainActor private func setupViewModel() {
        authenticationVerifyMsisdnViewModel.callback = { [weak self] result in
            guard let self = self else { return }
            MXLog.debug("[AuthenticationVerifyMsisdnCoordinator] AuthenticationVerifyMsisdnViewModel did complete with result: \(result).")
            
            switch result {
            case .send(let phoneNumber):
                self.sendSMS(phoneNumber)
            case .submitOTP(let otp):
                self.submitOTP(otp)
            case .resend:
                self.resendSMS()
            case .cancel:
                self.callback?(.cancel)
            case .goBack:
                self.authenticationVerifyMsisdnViewModel.goBackToMsisdnForm()
            }
        }
    }
    
    /// Show an activity indicator whilst loading.
    @MainActor private func startLoading() {
        loadingIndicator = indicatorPresenter.present(.loading(label: VectorL10n.loading, isInteractionBlocking: true))
    }
    
    /// Hide the currently displayed activity indicator.
    @MainActor private func stopLoading() {
        loadingIndicator = nil
    }
    
    /// Sends a validation SMS to the entered phone number and then waits for an OTP.
    @MainActor private func sendSMS(_ phoneNumber: String) {
        startLoading()
        
        currentTask = Task { [weak self] in
            do {
                let countryCode = try countryCodeFromPhoneNumber(phoneNumber)
                let threePID = RegisterThreePID.msisdn(msisdn: phoneNumber, countryCode: countryCode)
                let result = try await registrationWizard.addThreePID(threePID: threePID)
                
                // Shouldn't be reachable but just in case, continue the flow.
                
                guard !Task.isCancelled else { return }
                
                self?.callback?(.completed(result))
                self?.stopLoading()
            } catch RegistrationError.waitingForThreePIDValidation {
                // If three PID validation is required, show OTP screen.
                authenticationVerifyMsisdnViewModel.updateForSentSMS()
                self?.stopLoading()
            } catch is CancellationError {
                return
            } catch {
                self?.stopLoading()
                self?.handleError(error)
            }
        }
    }

    /// Submits OTP to verify the phone number.
    @MainActor private func submitOTP(_ otp: String) {
        startLoading()

        currentTask = Task { [weak self] in
            do {
                let result = try await registrationWizard.handleValidateThreePID(code: otp)
                
                // Shouldn't be reachable but just in case, continue the flow.

                guard !Task.isCancelled else { return }

                self?.callback?(.completed(result))
                self?.stopLoading()
            } catch is CancellationError {
                return
            } catch {
                self?.stopLoading()
                self?.handleError(error)
            }

        }
    }
    
    /// Resends an SMS to the previously entered phone number and then waits for user input for an OTP.
    @MainActor private func resendSMS() {
        startLoading()
        
        currentTask = Task { [weak self] in
            do {
                let result = try await registrationWizard.sendAgainThreePID()
                
                // Shouldn't be reachable but just in case, continue the flow.
                
                guard !Task.isCancelled else { return }
                
                self?.callback?(.completed(result))
                self?.stopLoading()
            } catch RegistrationError.waitingForThreePIDValidation {
                self?.stopLoading()
            } catch is CancellationError {
                return
            } catch {
                self?.stopLoading()
                self?.handleError(error)
            }
        }
    }
    
    /// Processes an error to either update the flow or display it to the user.
    @MainActor private func handleError(_ error: Error) {
        if let mxError = MXError(nsError: error as NSError) {
            authenticationVerifyMsisdnViewModel.displayError(.mxError(mxError.error))
            return
        }

        switch error {
        case RegistrationError.invalidPhoneNumber:
            authenticationVerifyMsisdnViewModel.displayError(.invalidPhoneNumber)
        default:
            authenticationVerifyMsisdnViewModel.displayError(.unknown)
        }
    }
}
