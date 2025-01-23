//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import SwiftUI
import UIKit

internal protocol MatrixItemChooserCoordinatorViewProvider {
    func view(with viewModel: MatrixItemChooserViewModelType.Context) -> AnyView
}

struct MatrixItemChooserCoordinatorParameters {
    let session: MXSession
    let title: String?
    let detail: String?
    let selectedItemsIds: [String]
    let viewProvider: MatrixItemChooserCoordinatorViewProvider?
    let itemsProcessor: MatrixItemChooserProcessorProtocol
    let selectionHeader: MatrixItemChooserSelectionHeader?
    
    init(session: MXSession,
         title: String? = nil,
         detail: String? = nil,
         selectedItemsIds: [String] = [],
         selectionHeader: MatrixItemChooserSelectionHeader? = nil,
         viewProvider: MatrixItemChooserCoordinatorViewProvider? = nil,
         itemsProcessor: MatrixItemChooserProcessorProtocol) {
        self.session = session
        self.title = title
        self.detail = detail
        self.selectedItemsIds = selectedItemsIds
        self.viewProvider = viewProvider
        self.itemsProcessor = itemsProcessor
        self.selectionHeader = selectionHeader
    }
}

final class MatrixItemChooserCoordinator: Coordinator, Presentable {
    // MARK: - Properties
    
    // MARK: Private
    
    private let parameters: MatrixItemChooserCoordinatorParameters
    private let matrixItemChooserHostingController: VectorHostingController
    private var matrixItemChooserViewModel: MatrixItemChooserViewModelProtocol

    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    var completion: ((MatrixItemChooserViewModelResult) -> Void)?
    
    // MARK: - Setup
    
    init(parameters: MatrixItemChooserCoordinatorParameters) {
        self.parameters = parameters
        let viewModel = MatrixItemChooserViewModel.makeMatrixItemChooserViewModel(matrixItemChooserService: MatrixItemChooserService(session: parameters.session, selectedItemIds: parameters.selectedItemsIds, itemsProcessor: parameters.itemsProcessor), title: parameters.title, detail: parameters.detail, selectionHeader: parameters.selectionHeader)
        matrixItemChooserViewModel = viewModel
        if let viewProvider = parameters.viewProvider {
            let view = viewProvider.view(with: viewModel.context)
                .environmentObject(AvatarViewModel(avatarService: AvatarService(mediaManager: parameters.session.mediaManager)))
            matrixItemChooserHostingController = VectorHostingController(rootView: view)
        } else {
            let view = MatrixItemChooser(viewModel: viewModel.context, listBottomPadding: nil)
                .environmentObject(AvatarViewModel(avatarService: AvatarService(mediaManager: parameters.session.mediaManager)))
            matrixItemChooserHostingController = VectorHostingController(rootView: view)
        }
    }
    
    // MARK: - Coordinator
    
    func start() {
        MXLog.debug("[MatrixItemChooserCoordinator] did start.")
        matrixItemChooserViewModel.completion = { [weak self] result in
            MXLog.debug("[MatrixItemChooserCoordinator] MatrixItemChooserViewModel did complete with result: \(result).")
            guard let self = self else { return }
            self.completion?(result)
        }
    }
    
    // MARK: - Presentable
    
    func toPresentable() -> UIViewController {
        matrixItemChooserHostingController
    }
}
