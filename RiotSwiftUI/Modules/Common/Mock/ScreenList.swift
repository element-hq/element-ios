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


import SwiftUI

@available(iOS 14.0, *)
struct ScreenList: View {
    
    private var allStates: [ScreenStateInfo]
    
    init(screens: [MockScreenState.Type]) {
        allStates = screens
            .map({ $0.stateRenderer })
            .flatMap{( $0.states )}
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(0..<allStates.count) { i in
                    let state = allStates[i]
                    NavigationLink(destination: state.view) {
                        Text(state.screenTitle)
                    }
                }
            }
        }
        .navigationTitle("Screen States")
    }
}

@available(iOS 14.0, *)
struct ScreenList_Previews: PreviewProvider {
    static var previews: some View {
        ScreenList(screens: [MockTemplateUserProfileScreenState.self])
    }
}
