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

class CallBarPresentOperation: AsyncOperation {
    
    private var presenter: CallPresenter
    private var activeCallVC: CallViewController?
    private var numberOfPausedCalls: UInt
    private var completion: (() -> Void)?
    
    init(presenter: CallPresenter,
         activeCallVC: CallViewController?,
         numberOfPausedCalls: UInt,
         completion: (() -> Void)? = nil) {
        self.presenter = presenter
        self.activeCallVC = activeCallVC
        self.numberOfPausedCalls = numberOfPausedCalls
        self.completion = completion
    }
    
    override func main() {
        presenter.delegate?.callPresenter(presenter, presentCallBarFor: activeCallVC, numberOfPausedCalls: numberOfPausedCalls, completion: {
            self.finish()
            self.completion?()
        })
    }
    
}
