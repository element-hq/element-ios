//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

/// The form shown to enter an OTP for phone number vaildation
struct AuthenticationVerifyMsisdnOTPForm: View {
    // MARK: - Properties
    
    // MARK: Private
    
    @Environment(\.theme) private var theme
    
    @State private var isEditingTextField = false
    
    // MARK: Public
    
    @ObservedObject var viewModel: AuthenticationVerifyMsisdnViewModel.Context
    
    // MARK: Views
    
    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.top, OnboardingMetrics.topPaddingToNavigationBar)
                .padding(.bottom, 36)
            
            mainContent
        }
    }
    
    /// The title, message and icon at the top of the screen.
    var header: some View {
        VStack(spacing: 8) {
            OnboardingIconImage(image: Asset.Images.authenticationMsisdnIcon)
                .padding(.bottom, 8)
            
            Text(VectorL10n.authenticationVerifyMsisdnWaitingTitle)
                .font(theme.fonts.title2B)
                .multilineTextAlignment(.center)
                .foregroundColor(theme.colors.primaryContent)
                .accessibilityIdentifier("titleLabel")
            
            Text(VectorL10n.authenticationVerifyMsisdnWaitingMessage(viewModel.phoneNumber))
                .font(theme.fonts.body)
                .multilineTextAlignment(.center)
                .foregroundColor(theme.colors.secondaryContent)
                .accessibilityIdentifier("messageLabel")
        }
    }
    
    /// The text field and submit button where the user enters an OTP.
    var mainContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            if #available(iOS 15.0, *) {
                textField
                    .onSubmit(submitOTP)
            } else {
                textField
            }

            Button { viewModel.send(viewAction: .resend) } label: {
                Text(VectorL10n.authenticationVerifyMsisdnWaitingButton)
                    .font(theme.fonts.body)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .accessibilityIdentifier("resendButton")
            .padding(.bottom, 26)

            Button(action: submitOTP) {
                Text(VectorL10n.next)
            }
            .buttonStyle(PrimaryActionButtonStyle())
            .disabled(viewModel.viewState.hasInvalidOTP)
            .accessibilityIdentifier("nextButton")
        }
    }
    
    /// The text field, extracted for iOS 15 modifiers to be applied.
    var textField: some View {
        TextField(VectorL10n.authenticationVerifyMsisdnOtpTextFieldPlaceholder, text: $viewModel.otp) {
            isEditingTextField = $0
        }
        .textFieldStyle(BorderedInputFieldStyle(isEditing: isEditingTextField, isError: false))
        .keyboardType(.decimalPad)
        .disableAutocorrection(true)
        .accessibilityIdentifier("otpTextField")
    }
    
    /// Sends the `submitOTP` view action so long as a valid OTP has been input.
    func submitOTP() {
        guard viewModel.viewState.hasSentSMS, !viewModel.viewState.hasInvalidOTP else { return }
        viewModel.send(viewAction: .submitOTP)
    }
}
