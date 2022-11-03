// 
// Copyright 2022 New Vector Ltd
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

@objcMembers
final class ComposerBridgePresenter: NSObject {
    // MARK: - Constants
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let coordinator: ComposerCoordinator
    
    // MARK: Public
        
    init(coordinator: ComposerCoordinator) {
        self.coordinator = coordinator
        super.init()
    }
    
    // MARK: - Setup
    
    // MARK: - Public
    
    // NOTE: Default value feature is not compatible with Objective-C.
    // func present(from viewController: UIViewController, animated: Bool) {
    //     self.present(from: viewController, animated: animated)
    // }
    
    func present(from viewController: UIViewController, animated: Bool) {
        let presentable = coordinator.toPresentable()
        viewController.present(presentable, animated: animated) { [weak coordinator] in
            coordinator?.viewModel.focus()
        }
        coordinator.start()
    }
    
    func dismiss(animated: Bool, completion: (() -> Void)?) {
        // Dismiss modal
        coordinator.toPresentable().dismiss(animated: animated) {
            completion?()
        }
    }
}

