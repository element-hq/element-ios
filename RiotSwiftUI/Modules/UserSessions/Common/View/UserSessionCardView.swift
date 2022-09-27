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

import DesignKit
import SwiftUI

struct UserSessionCardView: View {
    @Environment(\.theme) var theme: ThemeSwiftUI
    
    var viewData: UserSessionCardViewData
    
    var onVerifyAction: ((String) -> Void)?
    var onViewDetailsAction: ((String) -> Void)?
    var onLearnMoreAction: (() -> Void)?
    
    private var verificationStatusImageName: String {
        viewData.isVerified ? Asset.Images.userSessionVerified.name : Asset.Images.userSessionUnverified.name
    }
    
    private var verificationStatusText: String {
        viewData.isVerified ? VectorL10n.userSessionVerified : VectorL10n.userSessionUnverified
    }
    
    private var verificationStatusColor: Color {
        viewData.isVerified ? theme.colors.accent : theme.colors.alert
    }
    
    private var verificationStatusAdditionalInfoText: String {
        viewData.isVerified ? VectorL10n.userSessionVerifiedAdditionalInfo : VectorL10n.userSessionUnverifiedAdditionalInfo
    }
    
    private var backgroundShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 8)
    }
    
    private var showExtraInformations: Bool {
        viewData.isCurrentSessionDisplayMode == false && (viewData.lastActivityDateString.isEmptyOrNil == false || viewData.lastSeenIPInfo.isEmptyOrNil == false)
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 12) {
            DeviceAvatarView(viewData: viewData.deviceAvatarViewData)
            
            Text(viewData.sessionName)
                .font(theme.fonts.headline)
                .foregroundColor(theme.colors.primaryContent)
                .multilineTextAlignment(.center)
            
            HStack {
                Image(verificationStatusImageName)
                Text(verificationStatusText)
                    .font(theme.fonts.subheadline)
                    .foregroundColor(verificationStatusColor)
                    .multilineTextAlignment(.center)
            }
            
            if viewData.isCurrentSessionDisplayMode {
                Text(verificationStatusAdditionalInfoText)
                    .font(theme.fonts.footnote)
                    .foregroundColor(theme.colors.secondaryContent)
                    .multilineTextAlignment(.center)
            } else {
                InlineTextButton(verificationStatusAdditionalInfoText + " %@", tappableText: VectorL10n.userSessionLearnMore) {
                    onLearnMoreAction?()
                }
                .font(theme.fonts.footnote)
                .foregroundColor(theme.colors.secondaryContent)
                .multilineTextAlignment(.center)
            }
            
            if showExtraInformations {
                VStack(spacing: 2) {
                    if let lastActivityDateString = viewData.lastActivityDateString, lastActivityDateString.isEmpty == false {
                        Text(lastActivityDateString)
                            .font(theme.fonts.footnote)
                            .foregroundColor(theme.colors.secondaryContent)
                            .multilineTextAlignment(.center)
                    }
                    
                    if let lastSeenIPInfo = viewData.lastSeenIPInfo, lastSeenIPInfo.isEmpty == false {
                        Text(lastSeenIPInfo)
                            .font(theme.fonts.footnote)
                            .foregroundColor(theme.colors.secondaryContent)
                            .multilineTextAlignment(.center)
                    }
                }
            }
            
            if viewData.isVerified == false {
                Button {
                    onVerifyAction?(viewData.sessionId)
                } label: {
                    Text(VectorL10n.userSessionVerifyAction)
                        .font(theme.fonts.body)
                }
                .buttonStyle(PrimaryActionButtonStyle())
                .padding(.top, 4)
                .padding(.bottom, 3)
            }
            
            if viewData.isCurrentSessionDisplayMode {
                Button {
                    onViewDetailsAction?(viewData.sessionId)
                } label: {
                    Text(VectorL10n.userSessionViewDetails)
                        .font(theme.fonts.body)
                        .foregroundColor(theme.colors.accent)
                }
                .padding(.top, 4)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(theme.colors.background)
        .clipShape(backgroundShape)
        .shapedBorder(color: theme.colors.quinaryContent, borderWidth: 1.0, shape: backgroundShape)
    }
}

struct UserSessionCardViewPreview: View {
    @Environment(\.theme) var theme: ThemeSwiftUI
    
    let viewData: UserSessionCardViewData
    
    init(isCurrentSessionInfo: Bool = false) {
        let currentSessionInfo = UserSessionInfo(sessionId: "alice", sessionName: "iOS", deviceType: .mobile, isVerified: false, lastSeenIP: "10.0.0.10", lastSeenTimestamp: Date().timeIntervalSince1970 - 100)
        
        viewData = UserSessionCardViewData(userSessionInfo: currentSessionInfo, isCurrentSessionDisplayMode: isCurrentSessionInfo)
    }
    
    var body: some View {
        VStack {
            UserSessionCardView(viewData: viewData)
        }
        .frame(maxWidth: .infinity)
        .background(theme.colors.system)
        .padding()
    }
}

struct UserSessionCardView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            UserSessionCardViewPreview(isCurrentSessionInfo: true).theme(.light).preferredColorScheme(.light)
            UserSessionCardViewPreview(isCurrentSessionInfo: true).theme(.dark).preferredColorScheme(.dark)
            UserSessionCardViewPreview().theme(.light).preferredColorScheme(.light)
            UserSessionCardViewPreview().theme(.dark).preferredColorScheme(.dark)
        }
    }
}
