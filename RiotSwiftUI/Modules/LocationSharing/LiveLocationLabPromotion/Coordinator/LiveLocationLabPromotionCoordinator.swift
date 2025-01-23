//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
        
        liveLocationLabPromotionViewModel.completion = { [weak self] enableLiveLocation in
            guard let self = self else { return }

            RiotSettings.shared.enableLiveLocationSharing = enableLiveLocation

            self.completion?(enableLiveLocation)
        }
        
        liveLocationLabPromotionHostingController.presentationController?.delegate = self
    }
    
    func toPresentable() -> UIViewController {
        liveLocationLabPromotionHostingController
    }
}

// MARK: - UIAdaptivePresentationControllerDelegate

extension LiveLocationLabPromotionCoordinator: UIAdaptivePresentationControllerDelegate {
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        completion?(RiotSettings.shared.enableLiveLocationSharing)
    }
}
