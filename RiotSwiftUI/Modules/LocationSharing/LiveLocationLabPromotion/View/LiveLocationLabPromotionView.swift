//
// Copyright 2022 New Vector Ltd
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
