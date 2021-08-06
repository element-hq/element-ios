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
import Combine

@available(iOS 13.0, *)
class ThemeServiceObserver: ObservableObject {
    
    static let shared = ThemeServiceObserver()
    
    var cancelable: Cancellable?
    
    init() {
        let themePubliser = NotificationCenter.default.publisher(for: NSNotification.Name.themeServiceDidChangeTheme).map { _ in
            ThemeService.shared().themeIdentifier
        }
        cancelable = themePubliser.sink { [weak self] id in
            guard let self = self else { return }
            self.themeId = id
        }
    }
    @Published var themeId: ThemeIdentifier?
}
