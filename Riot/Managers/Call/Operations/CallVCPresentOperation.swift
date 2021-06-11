// 
// Copyright 2020 New Vector Ltd
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
