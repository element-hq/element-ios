//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import DesignKit
import SwiftUI

struct UserSessionCardView: View {
    @Environment(\.theme) var theme: ThemeSwiftUI
    
    var viewData: UserSessionCardViewData
    
    var onVerifyAction: ((String) -> Void)?
    var onViewDetailsAction: ((String) -> Void)?
    var onLearnMoreAction: (() -> Void)?
    
    private var backgroundShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 8)
    }
    
    enum DisplayMode {
        case compact
        case extended
    }
    
    let showLocationInformations: Bool
    let displayMode: DisplayMode
    
    private var showExtraInformations: Bool {
        displayMode == .extended && (viewData.lastActivityDateString.isEmptyOrNil == false || ipText.isEmptyOrNil == false)
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 12) {
            DeviceAvatarView(viewData: viewData.deviceAvatarViewData, isSelected: false, showVerificationBadge: false)
                .accessibilityHidden(true)
            
            Text(viewData.sessionName)
                .font(theme.fonts.headline)
                .foregroundColor(theme.colors.primaryContent)
                .multilineTextAlignment(.center)
            
            Label {
                Text(viewData.verificationStatusText)
                    .font(theme.fonts.subheadline)
                    .foregroundColor(theme.colors[keyPath: viewData.verificationStatusColor])
                    .multilineTextAlignment(.center)
            } icon: {
                Image(viewData.verificationStatusImageName)
                    .resizable()
                    .frame(width: 16, height: 16)
            }
            
            InlineTextButton(viewData.verificationStatusAdditionalInfoText, tappableText: VectorL10n.userSessionLearnMore, alwaysCallAction: false) {
                onLearnMoreAction?()
            }
            .font(theme.fonts.footnote)
            .foregroundColor(theme.colors.secondaryContent)
            .multilineTextAlignment(.center)
            
            if showExtraInformations {
                VStack(spacing: 2) {
                    HStack {
                        if let lastActivityIcon = viewData.lastActivityIcon {
                            Image(lastActivityIcon)
                                .padding(.leading, 2)
                        }
                        if let lastActivityDateString = viewData.lastActivityDateString, lastActivityDateString.isEmpty == false {
                            Text(lastActivityDateString)
                                .font(theme.fonts.footnote)
                                .foregroundColor(theme.colors.secondaryContent)
                                .multilineTextAlignment(.center)
                        }
                    }
                    if showLocationInformations, let ipText = ipText {
                        Text(ipText)
                            .font(theme.fonts.footnote)
                            .foregroundColor(theme.colors.secondaryContent)
                            .multilineTextAlignment(.center)
                    }
                }
            }
            
            if viewData.verificationState == .unverified {
                Button {
                    onVerifyAction?(viewData.sessionId)
                } label: {
                    Text(VectorL10n.userSessionVerifyAction)
                        .font(theme.fonts.body)
                }
                .buttonStyle(PrimaryActionButtonStyle())
                .padding(.top, 4)
                .padding(.bottom, 3)
                .accessibilityIdentifier("userSessionCardVerifyButton")
            }
            
            if viewData.isCurrentSessionDisplayMode, displayMode == .compact {
                Text(VectorL10n.userSessionViewDetails)
                    .font(theme.fonts.body)
                    .foregroundColor(theme.colors.accent)
                    .accessibilityIdentifier("userSessionCardViewDetails")
                    .padding(.top, 8)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(theme.colors.background)
        .clipShape(backgroundShape)
        .shapedBorder(color: theme.colors.quinaryContent, borderWidth: 0.5, shape: backgroundShape)
        .onTapGesture {
            if viewData.isCurrentSessionDisplayMode {
                onViewDetailsAction?(viewData.sessionId)
            }
        }
    }
    
    private var ipText: String? {
        guard let lastSeenIp = viewData.lastSeenIP, !lastSeenIp.isEmpty else {
            return nil
        }
        return viewData.lastSeenIPLocation.map { "\(lastSeenIp) (\($0))" } ?? lastSeenIp
    }
}

struct UserSessionCardViewPreview: View {
    @Environment(\.theme) var theme: ThemeSwiftUI
    
    let viewData: UserSessionCardViewData
    let displayMode: UserSessionCardView.DisplayMode

    init(isCurrent: Bool = false, verificationState: UserSessionInfo.VerificationState = .unverified, displayMode: UserSessionCardView.DisplayMode = .extended) {
        let sessionInfo = UserSessionInfo(id: "alice",
                                          name: "iOS",
                                          deviceType: .mobile,
                                          verificationState: verificationState,
                                          lastSeenIP: "10.0.0.10",
                                          lastSeenTimestamp: nil,
                                          applicationName: "Element iOS",
                                          applicationVersion: "1.0.0",
                                          applicationURL: nil,
                                          deviceModel: nil,
                                          deviceOS: "iOS 15.5",
                                          lastSeenIPLocation: nil,
                                          clientName: "Element",
                                          clientVersion: "1.0.0",
                                          isActive: true,
                                          isCurrent: isCurrent)
        viewData = UserSessionCardViewData(sessionInfo: sessionInfo)
        self.displayMode = displayMode
    }
    
    var body: some View {
        VStack {
            UserSessionCardView(viewData: viewData, showLocationInformations: true, displayMode: displayMode)
        }
        .frame(maxWidth: .infinity)
        .background(theme.colors.system)
        .padding()
    }
}

struct UserSessionCardView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            UserSessionCardViewPreview(isCurrent: true, displayMode: .compact).theme(.light).preferredColorScheme(.light)
            UserSessionCardViewPreview(isCurrent: true, displayMode: .extended).theme(.light).preferredColorScheme(.light)
            UserSessionCardViewPreview(isCurrent: true).theme(.dark).preferredColorScheme(.dark)
            UserSessionCardViewPreview().theme(.light).preferredColorScheme(.light)
            UserSessionCardViewPreview().theme(.dark).preferredColorScheme(.dark)
            
            UserSessionCardViewPreview(isCurrent: true, verificationState: .verified)
                .theme(.light).preferredColorScheme(.light)
            UserSessionCardViewPreview(verificationState: .verified)
                .theme(.light).preferredColorScheme(.light)
            UserSessionCardViewPreview(verificationState: .unknown)
                .theme(.light).preferredColorScheme(.light)
        }
    }
}
