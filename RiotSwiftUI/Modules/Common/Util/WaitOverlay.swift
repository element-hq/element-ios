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

/// A modifier for showing the wait overlay view over a view.
struct WaitOverlayModifier: ViewModifier {
    var allowUserInteraction: Bool
    var show: Bool
    var message: String?
    
    @ViewBuilder
    func body(content: Content) -> some View {
        content
            .modifier(WaitOverlay(
                allowUserInteraction: allowUserInteraction,
                message: message,
                isLoading: show
            ))
    }
}

extension View {
    func waitOverlay(show: Bool, message: String? = nil, allowUserInteraction: Bool = true) -> some View {
        modifier(WaitOverlayModifier(allowUserInteraction: allowUserInteraction, show: show, message: message))
    }
}

/// `WaitOverlay` allows to easily add an overlay that covers the entire with an `ActivityIndicator` at the center
struct WaitOverlay: ViewModifier {
    // MARK: - Properties
    
    var alignment: Alignment = .center
    var allowUserInteraction = true
    var message: String?
    var isLoading: Bool

    // MARK: - Private
    
    @Environment(\.theme) private var theme: ThemeSwiftUI

    // MARK: - Setup
    
    init(alignment: Alignment = .center,
         allowUserInteraction: Bool = true,
         message: String? = nil,
         isLoading: Bool) {
        self.message = message
        self.isLoading = isLoading
        self.alignment = alignment
        self.allowUserInteraction = allowUserInteraction
    }

    // MARK: - Public
    
    public func body(content: Content) -> some View {
        ZStack {
            content
            if isLoading {
                ZStack(alignment: alignment) {
                    if allowUserInteraction {
                        Color.clear
                    } else {
                        theme.colors.background.opacity(0.3)
                    }
                    VStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(1.3, anchor: .center)
                            .progressViewStyle(CircularProgressViewStyle(tint: theme.colors.secondaryContent))
                        if let message = message {
                            Text(message)
                                .font(theme.fonts.callout)
                                .foregroundColor(theme.colors.secondaryContent)
                        }
                    }
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(theme.colors.navigation.opacity(0.9)))
                }
                .edgesIgnoringSafeArea(.all)
                .transition(.opacity)
            }
        }
        .animation(.easeIn(duration: 0.2))
    }
}

struct WaitOverlay_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            VStack {
                ThemableNavigationBar(title: nil, showBackButton: true, backAction: { }, closeAction: { })
                ThemableNavigationBar(title: "Some Title", showBackButton: true, backAction: { }, closeAction: { })
                ThemableNavigationBar(title: nil, showBackButton: false, backAction: { }, closeAction: { })
                ThemableNavigationBar(title: "Some Title", showBackButton: false, backAction: { }, closeAction: { })
            }
            .modifier(WaitOverlay(isLoading: true))
            VStack {
                ThemableNavigationBar(title: nil, showBackButton: true, backAction: { }, closeAction: { })
                ThemableNavigationBar(title: "Some Title", showBackButton: true, backAction: { }, closeAction: { })
                ThemableNavigationBar(title: nil, showBackButton: false, backAction: { }, closeAction: { })
                ThemableNavigationBar(title: "Some Title", showBackButton: false, backAction: { }, closeAction: { })
            }
            .modifier(WaitOverlay(alignment: .topLeading, isLoading: true))
            VStack {
                ThemableNavigationBar(title: nil, showBackButton: true, backAction: { }, closeAction: { }).theme(.dark)
                ThemableNavigationBar(title: "Some Title", showBackButton: true, backAction: { }, closeAction: { }).theme(.dark)
                ThemableNavigationBar(title: nil, showBackButton: false, backAction: { }, closeAction: { }).theme(.dark)
                ThemableNavigationBar(title: "Some Title", showBackButton: false, backAction: { }, closeAction: { }).theme(.dark)
            }
            
            .modifier(WaitOverlay(isLoading: true)).theme(.dark)
            .preferredColorScheme(.dark)
        }
        .padding()
    }
}
