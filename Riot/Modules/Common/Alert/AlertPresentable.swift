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

/// AlertPresentable absracts an alert presenter
protocol AlertPresentable {
    
    func showError(_ error: Error, animated: Bool, completion: (() -> Void)?)
    func show(title: String?, message: String?, animated: Bool, completion: (() -> Void)?)
}

// MARK: Default implementation
extension AlertPresentable {
    
    func showError(_ error: Error) {
        self.showError(error, animated: true, completion: nil)
    }
    
    func show(title: String?, message: String?) {
        self.show(title: title, message: message, animated: true, completion: nil)
    }
}
