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
    
    typealias Completion = () -> Void
    // MARK: - Properties
    
    // MARK: Private
    
    private let session: MXSession
    private let templateUserProfileViewController: UIViewController
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    var completion: Completion?
    
    // MARK: - Setup
    
    @available(iOS 14.0, *)
    init(session: MXSession) {
        self.session = session
        let hostViewController = VectorHostingController()
        templateUserProfileViewController = UINavigationController(rootViewController: hostViewController)
        let rootView = TemplateUserProfile.instantiate(session: session, completion: self.userProfileCompletion(result:))
        hostViewController.setRoot(view: rootView)
    }
    
    @available(iOS 14.0, *)
    func userProfileCompletion(result: TemplateUserProfile.Result) {
        switch result {
        case .cancel, .done:
            completion?()
        break
        }
    }
    
    // MARK: - Public methods
    
    func start() {
        
    }
    
    func toPresentable() -> UIViewController {
        return self.templateUserProfileViewController
    }
}

@available(iOS 14.0, *)
extension TemplateUserProfile {
    static func instantiate(session: MXSession, completion: @escaping TemplateUserProfile.Completion) -> some View {
        let templateUserProfileViewModel = TemplateUserProfileViewModel(userService: MXTemplateUserService(session: session))
        let templateUserProfile = TemplateUserProfile(viewModel: templateUserProfileViewModel, completion: completion)
        return templateUserProfile.addDependency(MXAvatarService.instantiate(mediaManager: session.mediaManager))
    }
}
