// File created from SimpleUserProfileExample
// $ createScreen.sh Room/UserSuggestion UserSuggestion
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

@available(iOS 14.0, *)
final class UserSuggestionCoordinator: Coordinator {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let parameters: UserSuggestionCoordinatorParameters
    private let userSuggestionHostingController: UIViewController
    
    private var userSuggestionService: UserSuggestionServiceProtocol
    private var userSuggestionViewModel: UserSuggestionViewModelProtocol
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    var completion: (() -> Void)?
    
    // MARK: - Setup
    
    @available(iOS 14.0, *)
    init(parameters: UserSuggestionCoordinatorParameters) {
        self.parameters = parameters
        
        userSuggestionService = UserSuggestionService(room: parameters.room)
        userSuggestionViewModel = UserSuggestionViewModel.makeUserSuggestionViewModel(userSuggestionService: userSuggestionService)
        
        let view = UserSuggestionList(viewModel: userSuggestionViewModel.context)
            .addDependency(AvatarService.instantiate(mediaManager: parameters.mediaManager))
        
        userSuggestionHostingController = UIHostingController(rootView: view)
    }
    
    func processPartialUserName(_ userName: String) {
        userSuggestionService.processPartialUserName(userName)
    }
    
    // MARK: - Public
    func start() {
        
    }
    
    func toPresentable() -> UIViewController {
        return self.userSuggestionHostingController
    }
}
