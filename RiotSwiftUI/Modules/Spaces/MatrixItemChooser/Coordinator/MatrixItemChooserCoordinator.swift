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
            let view = viewProvider.view(with: viewModel.context).addDependency(AvatarService.instantiate(mediaManager: parameters.session.mediaManager))
            matrixItemChooserHostingController = VectorHostingController(rootView: view)
        } else {
            let view = MatrixItemChooser(viewModel: viewModel.context, listBottomPadding: nil)
                .addDependency(AvatarService.instantiate(mediaManager: parameters.session.mediaManager))
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
        return self.matrixItemChooserHostingController
    }
}
