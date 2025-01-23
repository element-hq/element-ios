// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import CommonKit
import MatrixSDK
import UIKit

/// A set of user interactors commonly used across the app
enum UserIndicatorType {
    case loading(label: String, isInteractionBlocking: Bool)
    case success(label: String)
    case failure(label: String)
    case custom(label: String, icon: UIImage?)
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
    private let presentationContext: UserIndicatorPresentationContext
    let queue: UserIndicatorQueue
    
    init(presentationContext: UserIndicatorPresentationContext) {
        self.presentationContext = presentationContext
        self.queue = UserIndicatorQueue()
    }
    
    convenience init(presentingViewController: UIViewController) {
        let context = StaticUserIndicatorPresentationContext(viewController: presentingViewController)
        self.init(presentationContext: context)
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
        case .failure(let label):
            return failureRequest(label: label)
        case .custom(let label, let icon):
            return customRequest(label: label, icon: icon)
        }
    }
    
    private func loadingRequest(label: String) -> UserIndicatorRequest {
        let presenter = ToastViewPresenter(
            viewState: .init(
                style: .loading,
                label: label
            ),
            presentationContext: presentationContext
        )
        return UserIndicatorRequest(
            presenter: presenter,
            dismissal: .manual
        )
    }
    
    private func fullScreenLoadingRequest(label: String) -> UserIndicatorRequest {
        let presenter = FullscreenLoadingViewPresenter(
            label: label,
            presentationContext: presentationContext
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
            presentationContext: presentationContext
        )
        return UserIndicatorRequest(
            presenter: presenter,
            dismissal: .timeout(1.5)
        )
    }
    
    private func failureRequest(label: String) -> UserIndicatorRequest {
        let presenter = ToastViewPresenter(
            viewState: .init(
                style: .failure,
                label: label
            ),
            presentationContext: presentationContext
        )
        return UserIndicatorRequest(
            presenter: presenter,
            dismissal: .timeout(1.5)
        )
    }
    
    private func customRequest(label: String, icon: UIImage?) -> UserIndicatorRequest {
        let presenter = ToastViewPresenter(
            viewState: .init(
                style: .custom(icon: icon),
                label: label
            ),
            presentationContext: presentationContext
        )
        return UserIndicatorRequest(
            presenter: presenter,
            dismissal: .manual
        )
    }
}
