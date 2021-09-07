/*
 Copyright 2021 New Vector Ltd
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

import Foundation
import UIKit
import SwiftUI

final class TemplateUserProfileCoordinator: Coordinator {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let session: MXSession
    private let templateUserProfileViewController: UIViewController
    private var templateUserProfileViewModel: TemplateUserProfileViewModelProtocol
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    var completion: (() -> Void)?
    
    // MARK: - Setup
    
    @available(iOS 14.0, *)
    init(session: MXSession) {
        self.session = session
        let viewModel = TemplateUserProfileViewModel(userService: MXTemplateUserProfileService(session: session))
        let view = TemplateUserProfile(viewModel: viewModel)
            .addDependency(MXAvatarService.instantiate(mediaManager: session.mediaManager))
        templateUserProfileViewModel = viewModel
        templateUserProfileViewController = VectorHostingController(rootView: view)
    }
    
    // MARK: - Public methods
    func start() {
        templateUserProfileViewModel.completion = { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .cancel, .done:
                self.completion?()
            break
            }
        }
    }
    
    func toPresentable() -> UIViewController {
        return self.templateUserProfileViewController
    }
}
