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

// MARK: - Coordinator

@available(iOS 13.0, *)
struct OnboardingSplashScreenPageContent {
    let title: String
    let message: String
    let image: ImageAsset
    let gradient: Gradient
}

// MARK: View model

enum OnboardingSplashScreenStateAction {
    case viewAction(OnboardingSplashScreenViewAction)
}

enum OnboardingSplashScreenViewModelResult {
    case register
    case login
}

// MARK: View

@available(iOS 13.0, *)
struct OnboardingSplashScreenViewState: BindableState {
    let content: [OnboardingSplashScreenPageContent]
    var bindings: OnboardingSplashScreenBindings
    
    init() {
        self.content = [
            OnboardingSplashScreenPageContent(title: VectorL10n.onboardingSplashPage1Title,
                                              message: VectorL10n.onboardingSplashPage1Message,
                                              image: Asset.Images.onboardingSplashScreenPage1,
                                              gradient: Gradient(colors: [
                                                Color(red: 0.73, green: 0.91, blue: 0.81),
                                                Color(red: 0.45, green: 0.78, blue: 0.85)
                                              ])),
            OnboardingSplashScreenPageContent(title: VectorL10n.onboardingSplashPage2Title,
                                              message: VectorL10n.onboardingSplashPage2Message,
                                              image: Asset.Images.onboardingSplashScreenPage2,
                                              gradient: Gradient(colors: [
                                                Color(red: 0.45, green: 0.78, blue: 0.85),
                                                Color(red: 0.72, green: 0.45, blue: 0.85)
                                              ])),
            OnboardingSplashScreenPageContent(title: VectorL10n.onboardingSplashPage3Title,
                                              message: VectorL10n.onboardingSplashPage3Message,
                                              image: Asset.Images.onboardingSplashScreenPage3,
                                              gradient: Gradient(colors: [
                                                Color(red: 0.72, green: 0.45, blue: 0.85),
                                                Color(red: 0.05, green: 0.74, blue: 0.55)
                                              ])),
            OnboardingSplashScreenPageContent(title: VectorL10n.onboardingSplashPage4Title,
                                              message: VectorL10n.onboardingSplashPage4Message,
                                              image: Asset.Images.onboardingSplashScreenPage4,
                                              gradient: Gradient(colors: [
                                                Color(red: 0.05, green: 0.74, blue: 0.55),
                                                Color(red: 0.73, green: 0.91, blue: 0.81)
                                              ])),
        ]
        self.bindings = OnboardingSplashScreenBindings()
    }
}

struct OnboardingSplashScreenBindings {
    var pageIndex = 0
}

enum OnboardingSplashScreenViewAction {
    case register
    case login
    case nextPage
    case hiddenPage
}
