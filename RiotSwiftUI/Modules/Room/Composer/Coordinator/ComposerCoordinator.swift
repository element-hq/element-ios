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

final class ComposerCoordinator: NSObject, Coordinator, Presentable, UISheetPresentationControllerDelegate {
    // MARK: - Properties
    
    // MARK: Private
    
    private let hostingController: UIViewController
    
    // MARK: Public
    let viewModel: ComposerViewModelProtocol

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    
    // MARK: - Setup
    
    init(hostingVC: VectorHostingController, viewModel: ComposerViewModelProtocol) {
        
        hostingVC.bottomSheetPreferences = VectorHostingBottomSheetPreferences(
            detents: [.medium],
            prefersGrabberVisible: true,
            cornerRadius: 20,
            prefersScrollingExpandsWhenScrolledToEdge: false
        )
        hostingController = hostingVC
        self.viewModel = viewModel
        super.init()
        hostingController.presentationController?.delegate = self
        hostingVC.bottomSheetPreferences?.setup(viewController: hostingVC)
    }
    
    // MARK: - Public
    
    func start() {
        
    }
    
    func toPresentable() -> UIViewController {
        hostingController
    }
    
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
    }
}
