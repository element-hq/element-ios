// 
// Copyright 2020-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

class CallVCPresentOperation: AsyncOperation {
    
    private var presenter: CallPresenter
    private var callVC: UIViewController
    private var completion: (() -> Void)?
    
    init(presenter: CallPresenter,
         callVC: UIViewController,
         completion: (() -> Void)? = nil) {
        self.presenter = presenter
        self.callVC = callVC
        self.completion = completion
    }
    
    override func main() {
        if let pipable = callVC as? PictureInPicturable {
            pipable.willExitPiP?()
        }
        presenter.delegate?.callPresenter(presenter, presentCallViewController: callVC, completion: {
            self.finish()
            if let pipable = self.callVC as? PictureInPicturable {
                pipable.didExitPiP?()
                self.callVC.view.isUserInteractionEnabled = true
            }
            self.completion?()
        })
    }
    
}
