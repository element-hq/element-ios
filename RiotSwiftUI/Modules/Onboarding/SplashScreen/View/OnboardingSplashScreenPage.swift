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
struct OnboardingSplashScreenPage: View {
    
    // MARK: - Properties
    
    // MARK: Private
    @Environment(\.theme) private var theme
    
    // MARK: Public
    let content: OnboardingSplashScreenPageContent
    let overlayHeight: CGFloat
    
    // MARK: - Views
    
    var title: some View {
        Text(content.title)
            + Text(".")
            .foregroundColor(theme.colors.accent)
    }
    
    var backgroundGradient: some View {
        LinearGradient(gradient: content.gradient, startPoint: .leading, endPoint: .trailing)
            .flipsForRightToLeftLayoutDirection(true)
            .opacity(0.2)
    }
    
    var body: some View {
        VStack {
            Spacer()
            
            Image(content.image.name)
//                .resizable()
//                .scaledToFit()
//                .padding()
            
            Spacer()
            
            VStack(spacing: 8) {
                title
                    .font(theme.fonts.title2B)
                    .foregroundColor(theme.colors.primaryContent)
                Text(content.message)
                    .font(theme.fonts.body)
                    .foregroundColor(theme.colors.secondaryContent)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            Spacer()
                .frame(height: overlayHeight)
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(backgroundGradient.ignoresSafeArea())
    }
}

@available(iOS 14.0, *)
struct OnboardingSplashScreenPage_Previews: PreviewProvider {
    static let content = OnboardingSplashScreenViewState().content
    static var previews: some View {
        ForEach(0..<content.count, id:\.self) { index in
            OnboardingSplashScreenPage(content: content[index], overlayHeight: 55)
        }
    }
}
