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

struct AuthenticationVerifyMsisdnScreen: View {

    // MARK: - Properties
    
    // MARK: Private
    
    @Environment(\.theme) private var theme
    
    // MARK: Public
    
    @ObservedObject var viewModel: AuthenticationVerifyMsisdnViewModel.Context
    
    // MARK: Views
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                ScrollView {
                    if viewModel.viewState.hasSentSMS {
                        AuthenticationVerifyMsisdnOTPForm(viewModel: viewModel)
                            .readableFrame()
                            .padding(.horizontal, 16)
                    } else {
                        AuthenticationVerifyMsisdnForm(viewModel: viewModel)
                            .readableFrame()
                            .padding(.horizontal, 16)
                    }
                }
            }
        }
        .background(background.ignoresSafeArea())
        .toolbar { toolbar }
        .alert(item: $viewModel.alertInfo) { $0.alert }
        .accentColor(theme.colors.accent)
    }

    @ViewBuilder
    /// The view's background, which will show a gradient in light mode after sending the email.
    var background: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                theme.colors.background
                
                if viewModel.viewState.hasSentSMS && !theme.isDark {
                    gradient
                        .frame(height: geometry.size.height * 0.65)
                }
            }
        }
    }
    
    /// The background gradient shown after sending the email.
    var gradient: some View {
        LinearGradient(gradient: viewModel.viewState.gradient,
                       startPoint: .leading,
                       endPoint: .trailing)
            .opacity(0.3)
            .mask(LinearGradient(colors: [.white, .clear],
                                 startPoint: .top,
                                 endPoint: .bottom))
    }
    
    /// A simple toolbar with a cancel button.
    var toolbar: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            if viewModel.viewState.hasSentSMS {
                Button(VectorL10n.back) {
                    viewModel.send(viewAction: .goBack)
                }
            } else {
                Button(VectorL10n.cancel) {
                    viewModel.send(viewAction: .cancel)
                }
            }
        }
    }
}

// MARK: - Previews

struct AuthenticationVerifyMsisdnScreen_Previews: PreviewProvider {
    static let stateRenderer = MockAuthenticationVerifyMsisdnScreenState.stateRenderer
    static var previews: some View {
        stateRenderer.screenGroup(addNavigation: true)
            .navigationViewStyle(.stack)
        stateRenderer.screenGroup(addNavigation: true)
            .navigationViewStyle(.stack)
            .theme(.dark).preferredColorScheme(.dark)
    }
}
