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

@available(iOS 14.0, *)
struct WaitModalContentView: View {
    
    // MARK: - Properties
    
    var alignment: Alignment = .center
    @State var message: String? = nil

    // MARK: Private
    
    @Environment(\.theme) private var theme: ThemeSwiftUI
        
    // MARK: - Public
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
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
    }
}

@available(iOS 14.0, *)
struct WaitModalView: ViewModifier {
    // MARK: - Properties
    
    var alignment: Alignment = .center
    @State var message: String? = nil
    @Binding var isLoading: Bool
    
    // MARK: - Private
    
    @Environment(\.theme) private var theme: ThemeSwiftUI

    // MARK: - Public
    
    public func body(content: Content) -> some View
    {
        content
            .modal(withStyle: .overFullScreen,
                   modalTransitionStyle: .crossDissolve,
                   id: "WaitModalView",
                   isPresented: $isLoading) {
                WaitModalContentView(alignment: alignment, message: message)
            }
    }
    
    private var contentView: some View {
        ZStack {
            theme.colors.primaryContent.opacity(0.75)
            VStack(spacing: 12) {
                ProgressView()
                    .scaleEffect(1.3, anchor: .center)
                    .progressViewStyle(CircularProgressViewStyle(tint:      theme.colors.secondaryContent))
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
    }
}

@available(iOS 14.0, *)
struct WaitModalView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            VStack {
                ThemableNavigationBar(title: nil, showBackButton: true, backAction: {}, closeAction: {})
                ThemableNavigationBar(title: "Some Title", showBackButton: true, backAction: {}, closeAction: {})
                ThemableNavigationBar(title: nil, showBackButton: false, backAction: {}, closeAction: {})
                ThemableNavigationBar(title: "Some Title", showBackButton: false, backAction: {}, closeAction: {})
            }
            .modifier(WaitModalView(isLoading: .constant(true)))
            VStack {
                ThemableNavigationBar(title: nil, showBackButton: true, backAction: {}, closeAction: {})
                ThemableNavigationBar(title: "Some Title", showBackButton: true, backAction: {}, closeAction: {})
                ThemableNavigationBar(title: nil, showBackButton: false, backAction: {}, closeAction: {})
                ThemableNavigationBar(title: "Some Title", showBackButton: false, backAction: {}, closeAction: {})
            }
            .modifier(WaitModalView(alignment:.topLeading, isLoading: .constant(true)))
            VStack {
                ThemableNavigationBar(title: nil, showBackButton: true, backAction: {}, closeAction: {}).theme(.dark)
                ThemableNavigationBar(title: "Some Title", showBackButton: true, backAction: {}, closeAction: {}).theme(.dark)
                ThemableNavigationBar(title: nil, showBackButton: false, backAction: {}, closeAction: {}).theme(.dark)
                ThemableNavigationBar(title: "Some Title", showBackButton: false, backAction: {}, closeAction: {}).theme(.dark)
            }
            
            .modifier(WaitModalView(isLoading: .constant(true))).theme(.dark)
            .preferredColorScheme(.dark)
        }
        .padding()
    }
}
