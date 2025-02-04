//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct LiveLocationLabPromotionView: View {
    // MARK: - Properties
    
    // MARK: Private
    
    @Environment(\.theme) private var theme
        
    @ObservedObject var viewModel: LiveLocationLabPromotionViewModel.Context
    
    // MARK: - View
    
    var body: some View {
        VStack {
            VStack {
                Image(uiImage: Asset.Images.locationLiveIcon.image)
                    .resizable()
                    .frame(width: 60, height: 60)
                    .padding(.top, 15)
                
                Text(VectorL10n.locationSharingLiveLabPromotionTitle)
                    .font(theme.fonts.title2B)
                    .multilineTextAlignment(.center)
                    .foregroundColor(theme.colors.primaryContent)
                    .padding(.top, 15)
                
                Text(VectorL10n.locationSharingLiveLabPromotionText)
                    .font(theme.fonts.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(theme.colors.primaryContent)
                    .padding(.top, 1)
                
                Toggle(isOn: $viewModel.enableLabFlag) {
                    Text(VectorL10n.locationSharingLiveLabPromotionActivation)
                        .font(theme.fonts.body)
                        .foregroundColor(theme.colors.primaryContent)
                }
                .padding(.top)
                
                Button {
                    self.viewModel.send(viewAction: .complete)
                } label: {
                    Text(VectorL10n.ok)
                        .font(theme.fonts.bodySB)
                }
                .buttonStyle(PrimaryActionButtonStyle())
                .padding(.top, 20)
            }
            .padding()
        }
        .frame(maxHeight: .infinity)
        .background(theme.colors.background.ignoresSafeArea())
        .accentColor(theme.colors.accent)
    }
}

// MARK: - Previews

@available(iOS 15.0, *)
struct LiveLocationLabPromotion_Previews: PreviewProvider {
    static let stateRenderer = MockLiveLocationLabPromotionScreenState.stateRenderer
    static var previews: some View {
        stateRenderer.screenGroup()
    }
}
