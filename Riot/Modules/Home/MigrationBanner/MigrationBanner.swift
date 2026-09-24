// 
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

/// A banner inviting the user to migrate to the new app, displayed at the top of the room list.
struct MigrationBanner: View {
    @Environment(\.theme) private var theme: ThemeSwiftUI
    
    let title: String
    /// The body of the banner. `https://` URLs it contains are rendered as tappable links.
    let message: String
    /// The label of the download button. `nil` hides the button.
    let buttonTitle: String?
    /// Whether the icon of the default replacement app is displayed next to the title.
    let showsAppIcon: Bool
    let downloadAction: () -> Void
    let closeAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(alignment: .top, spacing: 16) {
                if showsAppIcon {
                    Image(Asset.Images.sunsetBannerIcon.name)
                        .resizable()
                        .frame(width: 48, height: 48)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .accessibilityHidden(true)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .top, spacing: 4) {
                        Text(title)
                            .font(theme.fonts.headline)
                            .foregroundStyle(theme.colors.primaryContent)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Button(action: closeAction) {
                            Image(Asset.Images.closeBanner.name)
                                .renderingMode(.template)
                                .resizable()
                                .frame(width: 20, height: 20)
                                .foregroundStyle(theme.colors.secondaryContent)
                        }
                        .accessibilityLabel(VectorL10n.close)
                        .accessibilityIdentifier("migrationBannerCloseButton")
                    }

                    Text(Self.attributedMessage(message))
                        .font(theme.fonts.subheadline)
                        .foregroundStyle(theme.colors.secondaryContent)
                        .tint(theme.colors.links)
                }
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            if let buttonTitle = buttonTitle {
                Button(buttonTitle) {
                    downloadAction()
                }
                .buttonStyle(PrimaryActionButtonStyle(font: theme.fonts.bodySB))
                .accessibilityIdentifier("migrationBannerDownloadButton")
            }
        }
        .padding(EdgeInsets(top: 12, leading: 12, bottom: 16, trailing: 12))
        .background(theme.colors.background, in: RoundedRectangle(cornerRadius: 8))
        .shapedBorder(color: theme.colors.quinaryContent, borderWidth: 1, shape: RoundedRectangle(cornerRadius: 8))
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .accessibilityIdentifier("migrationBanner")
    }
    
    private static let linkDetector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
    
    /// Turn the `https://` URLs contained in the message into tappable links.
    private static func attributedMessage(_ message: String) -> AttributedString {
        var attributedMessage = AttributedString(message)
        
        guard let linkDetector = linkDetector else {
            return attributedMessage
        }
        
        let matches = linkDetector.matches(in: message, range: NSRange(message.startIndex..., in: message))
        for match in matches {
            guard let url = match.url,
                  url.scheme?.lowercased() == "https",
                  let range = Range(match.range, in: attributedMessage) else {
                continue
            }
            attributedMessage[range].link = url
        }
        
        return attributedMessage
    }
}

// MARK: - Previews

struct MigrationBanner_Previews: PreviewProvider {
    static var previews: some View {
        MigrationBanner(title: VectorL10n.migrationBannerTitle,
                        message: VectorL10n.migrationBannerBody,
                        buttonTitle: VectorL10n.migrationBannerDownloadButton,
                        showsAppIcon: true,
                        downloadAction: { },
                        closeAction: { })
            .theme(.light)
            .previewDisplayName("Light")

        MigrationBanner(title: VectorL10n.migrationBannerTitle,
                        message: VectorL10n.migrationBannerBody,
                        buttonTitle: VectorL10n.migrationBannerDownloadButton,
                        showsAppIcon: true,
                        downloadAction: { },
                        closeAction: { })
            .theme(.dark)
            .preferredColorScheme(.dark)
            .previewDisplayName("Dark")
        
        MigrationBanner(title: "Time to move",
                        message: "Get the new app at https://element.io/download and follow the instructions from IT.",
                        buttonTitle: nil,
                        showsAppIcon: false,
                        downloadAction: { },
                        closeAction: { })
            .theme(.light)
            .previewDisplayName("Custom content, no button")
    }
}
