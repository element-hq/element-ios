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
import CommonKit
import MatrixSDK
import UIKit

/// A set of user interactors commonly used across the app
enum UserIndicatorType {
    case loading(label: String, isInteractionBlocking: Bool)
    case success(label: String)
}

/// A presenter which can handle `UserIndicatorType` by creating the underlying `UserIndicator`
/// and adding it to its `UserIndicatorQueue`
protocol UserIndicatorTypePresenterProtocol {
    /// Present a new type of user indicator, such as loading spinner or success message.
    ///
    /// The presenter will internally convert the type into a `UserIndicator` and add it to its internal queue
    /// of other indicators.
    ///
    /// If the queue is empty, the indicator will be displayed immediately, otherwise it will be pending
    /// until the previously added indicators have completed / been cancelled.
    ///
    /// To remove an indicator, `cancel` or deallocate the returned `UserIndicator`
    func present(_ type: UserIndicatorType) -> UserIndicator
    
    /// The queue of user indicators owned by the presenter
    ///
    /// Clients can access the queue to add custom `UserIndicatorRequest`s
    /// above and beyond those defined by `UserIndicatorType`
    var queue: UserIndicatorQueue { get }
}

class UserIndicatorTypePresenter: UserIndicatorTypePresenterProtocol {
    private weak var viewController: UIViewController?
    
    // In the existing app architecture it is often view controllers which instantiate
    // various presenters (errors, alerts ... ) and present on self. Since the presenting view controller
    // needs to be passed on init, it must be declared as weak, otherwise a retain cycle would occur.
    private var presentingViewController: UIViewController {
        guard let viewController = viewController else {
            MXLog.error("[UserIndicatorTypePresenter]: Presenting view controller is not available")
            return UIViewController()
        }
        return viewController
    }
    
    let queue: UserIndicatorQueue
    
    init(presentingViewController: UIViewController) {
        self.viewController = presentingViewController
        self.queue = UserIndicatorQueue()
    }
    
    func present(_ type: UserIndicatorType) -> UserIndicator {
        let request = userIndicatorRequest(for: type)
        return queue.add(request)
    }
    
    private func userIndicatorRequest(for type: UserIndicatorType) -> UserIndicatorRequest {
        switch type {
        case .loading(let label, let isInteractionBlocking):
            if isInteractionBlocking {
                return fullScreenLoadingRequest(label: label)
            } else {
                return loadingRequest(label: label)
            }
        case .success(let label):
            return successRequest(label: label)
        }
    }
    
    private func loadingRequest(label: String) -> UserIndicatorRequest {
        let presenter = ToastViewPresenter(
            viewState: .init(
                style: .loading,
                label: label
            ),
            presentingViewController: presentingViewController
        )
        return UserIndicatorRequest(
            presenter: presenter,
            dismissal: .manual
        )
    }
    
    private func fullScreenLoadingRequest(label: String) -> UserIndicatorRequest {
        let presenter = FullscreenLoadingViewPresenter(
            label: label,
            presentingViewController: presentingViewController
        )
        return UserIndicatorRequest(
            presenter: presenter,
            dismissal: .manual
        )
    }
    
    private func successRequest(label: String) -> UserIndicatorRequest {
        let presenter = ToastViewPresenter(
            viewState: .init(
                style: .success,
                label: label
            ),
            presentingViewController: presentingViewController
        )
        return UserIndicatorRequest(
            presenter: presenter,
            dismissal: .timeout(1.5)
        )
    }
}
