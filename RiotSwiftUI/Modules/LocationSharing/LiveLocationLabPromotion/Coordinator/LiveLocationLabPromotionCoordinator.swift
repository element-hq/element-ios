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

import SwiftUI

final class LiveLocationLabPromotionCoordinator: NSObject, Coordinator, Presentable {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let liveLocationLabPromotionHostingController: VectorHostingController
    private var liveLocationLabPromotionViewModel: LiveLocationLabPromotionViewModelProtocol
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    
    /// Closure called when coordinator completes. Indicates true if the lab flag has been enabled.
    var completion: ((Bool) -> Void)?
        
    // MARK: - Setup
    
    override init() {
        let viewModel = LiveLocationLabPromotionViewModel()
        let view = LiveLocationLabPromotionView(viewModel: viewModel.context)
        liveLocationLabPromotionViewModel = viewModel
        liveLocationLabPromotionHostingController = VectorHostingController(rootView: view)
        liveLocationLabPromotionHostingController.bottomSheetPreferences = VectorHostingBottomSheetPreferences()
        
        super.init()
    }
    
    // MARK: - Public
    
    func start() {
        MXLog.debug("[LiveLocationLabPromotionCoordinator] did start.")
        
        self.liveLocationLabPromotionViewModel.completion = { [weak self] enableLiveLocation in
            guard let self = self else { return }

            RiotSettings.shared.enableLiveLocationSharing = enableLiveLocation

            self.completion?(enableLiveLocation)
        }
        
        liveLocationLabPromotionHostingController.presentationController?.delegate = self
    }
    
    func toPresentable() -> UIViewController {
        return self.liveLocationLabPromotionHostingController
    }
}

// MARK: - UIAdaptivePresentationControllerDelegate

extension LiveLocationLabPromotionCoordinator: UIAdaptivePresentationControllerDelegate {
    
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        self.completion?(RiotSettings.shared.enableLiveLocationSharing)
    }
}
