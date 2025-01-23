// 
// Copyright 2020-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

@objc
protocol CallPresenterDelegate: AnyObject {
    //  Call screens
    func callPresenter(_ presenter: CallPresenter,
                       presentCallViewController viewController: UIViewController,
                       completion:(() -> Void)?)
    func callPresenter(_ presenter: CallPresenter,
                       dismissCallViewController viewController: UIViewController,
                       completion:(() -> Void)?)
    
    //  PiP
    func callPresenter(_ presenter: CallPresenter,
                       enterPipForCallViewController viewController: UIViewController,
                       completion:(() -> Void)?)
    
    func callPresenter(_ presenter: CallPresenter,
                       exitPipForCallViewController viewController: UIViewController,
                       completion:(() -> Void)?)
}
