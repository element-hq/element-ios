// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import CommonKit

/// An abstraction on top of `UserIndicatorTypePresenterProtocol` which manages and stores the individual user indicators.
/// When used to present an indicator the `UserIndicatorStore` will instead returns a simple callback function to the clients
/// letting them cancel the indicators without worrying about memory.
@objc final class UserIndicatorStore: NSObject {
    private let presenter: UserIndicatorTypePresenterProtocol
    private var indicators: [UserIndicator]
    
    @objc init(from viewController: UIViewController) {
        self.presenter = UserIndicatorTypePresenter(presentingViewController: viewController)
        self.indicators = []

        super.init()
    }
    
    init(presenter: UserIndicatorTypePresenterProtocol) {
        self.presenter = presenter
        self.indicators = []
    }
    
    /// Present a new type of user indicator, such as loading spinner or success message.
    /// To remove an indicator, call the returned `UserIndicatorCancel` function
    func present(type: UserIndicatorType) -> UserIndicatorCancel {
        let indicator = presenter.present(type)
        indicators.append(indicator)
        return {
            indicator.cancel()
        }
    }
    
    /// Present a loading indicator.
    /// To remove the indicator call the returned `UserIndicatorCancel` function
    ///
    /// Note: This is a convenience function callable by objective-c code
    @objc func presentLoading(label: String, isInteractionBlocking: Bool) -> UserIndicatorCancel {
        present(
            type: .loading(
                label: label,
                isInteractionBlocking: isInteractionBlocking
            )
        )
    }
    
    /// Present a success message that will be automatically dismissed after a few seconds.
    ///
    /// Note: This is a convenience function callable by objective-c code
    @objc func presentSuccess(label: String) {
        let indicator = presenter.present(.success(label: label))
        indicators.append(indicator)
    }
    
    /// Present an error message that will be automatically dismissed after a few seconds.
    ///
    /// Note: This is a convenience function callable by objective-c code
    @objc func presentFailure(label: String) {
        let indicator = presenter.present(.failure(label: label))
        indicators.append(indicator)
    }
    
    /// Present an custom message
    /// To remove the indicator call the returned `UserIndicatorCancel` function
    ///
    /// Note: This is a convenience function callable by objective-c code
    @objc func presentCustom(label: String, icon: UIImage?) -> UserIndicatorCancel {
        let indicator = presenter.present(.custom(label: label, icon: icon))
        indicators.append(indicator)
        return {
            indicator.cancel()
        }
    }
}
