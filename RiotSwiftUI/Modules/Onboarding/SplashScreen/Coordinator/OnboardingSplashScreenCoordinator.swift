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

import Foundation
import UIKit
import SwiftUI

struct OnboardingSplashScreenCoordinatorParameters { }

final class OnboardingSplashScreenCoordinator: Coordinator, Presentable {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let parameters: OnboardingSplashScreenCoordinatorParameters
    private let onboardingSplashScreenHostingController: UIViewController
    private var onboardingSplashScreenViewModel: OnboardingSplashScreenViewModelProtocol
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    var completion: ((OnboardingSplashScreenViewModelResult) -> Void)?
    
    // MARK: - Setup
    
    @available(iOS 14.0, *)
    init(parameters: OnboardingSplashScreenCoordinatorParameters) {
        self.parameters = parameters
        let viewModel = OnboardingSplashScreenViewModel()
        let view = OnboardingSplashScreen(viewModel: viewModel.context)
        onboardingSplashScreenViewModel = viewModel
        let hostingController = VectorHostingController(rootView: view)
        hostingController.isLockedToPortraitOnPhone = true
        onboardingSplashScreenHostingController = hostingController
    }
    
    // MARK: - Public
    func start() {
        MXLog.debug("[OnboardingSplashScreenCoordinator] did start.")
        onboardingSplashScreenViewModel.completion = { [weak self] result in
            MXLog.debug("[OnboardingSplashScreenCoordinator] OnboardingSplashScreenViewModel did complete with result: \(result).")
            guard let self = self else { return }
            switch result {
            case .login, .register:
                self.completion?(result)
            }
        }
    }
    
    func toPresentable() -> UIViewController {
        return self.onboardingSplashScreenHostingController
    }
}
