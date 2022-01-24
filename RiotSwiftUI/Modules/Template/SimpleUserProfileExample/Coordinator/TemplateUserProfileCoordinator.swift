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

struct TemplateUserProfileCoordinatorParameters {
    let session: MXSession
}

final class TemplateUserProfileCoordinator: Coordinator, Presentable {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let parameters: TemplateUserProfileCoordinatorParameters
    private let templateUserProfileHostingController: UIViewController
    private var templateUserProfileViewModel: TemplateUserProfileViewModelProtocol
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    var completion: (() -> Void)?
    
    // MARK: - Setup
    
    @available(iOS 14.0, *)
    init(parameters: TemplateUserProfileCoordinatorParameters) {
        self.parameters = parameters
        let viewModel = TemplateUserProfileViewModel.makeTemplateUserProfileViewModel(templateUserProfileService: TemplateUserProfileService(session: parameters.session))
        let view = TemplateUserProfile(viewModel: viewModel.context)
            .addDependency(AvatarService.instantiate(mediaManager: parameters.session.mediaManager))
        templateUserProfileViewModel = viewModel
        templateUserProfileHostingController = VectorHostingController(rootView: view)
    }
    
    // MARK: - Public
    func start() {
        MXLog.debug("[TemplateUserProfileCoordinator] did start.")
        templateUserProfileViewModel.completion = { [weak self] result in
            MXLog.debug("[TemplateUserProfileCoordinator] TemplateUserProfileViewModel did complete with result: \(result).")
            guard let self = self else { return }
            switch result {
            case .cancel, .done:
                self.completion?()
            }
        }
    }
    
    func toPresentable() -> UIViewController {
        return self.templateUserProfileHostingController
    }
}
