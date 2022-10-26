// 
// Copyright 2022 New Vector Ltd
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

import SwiftUI

struct InfoView: View {
    struct Action {
        let text: String
        let action: () -> Void
    }
    private let title: String
    private let description: String
    private let action: Action
    
    init(title: String, descripion: String, action: Action) {
        self.title = title
        self.description = descripion
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                Text(title)
                Text(description)
            }
            
            Button(action: action.action) {
                Text(action.text)
            }
        }
    }
}

struct InfoView_Previews: PreviewProvider {
    static var previews: some View {
        InfoView(title: "Verified sessions",
                 descripion: "Further context on verified sessions. What do those mean, and how do they differ from unverified ones.\n\nWe could provide a link to an external reference resource for even more context.",
                 action: .init(text: "GOT IT", action: {}))
    }
}
