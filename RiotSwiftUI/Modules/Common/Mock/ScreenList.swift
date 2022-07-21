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

struct ScreenList: View {
    
    private let allStates: [ScreenStateInfo]
    
    @State private var searchQuery = ""
    @State private var filteredStates: [ScreenStateInfo]
    
    init(screens: [MockScreenState.Type]) {
        let states = screens
            .map { $0.stateRenderer }
            .flatMap { $0.states }
        
        allStates = states
        filteredStates = states
    }
    
    var body: some View {
        NavigationView {
            VStack {
                TextField("Search", text: $searchQuery)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)
                    .accessibilityIdentifier("searchQueryTextField")
                    .onChange(of: searchQuery, perform: search)
                
                Form {
                    SwiftUI.Section {
                        ForEach(0..<filteredStates.count, id: \.self) { i in
                            let state = filteredStates[i]
                            NavigationLink(destination: state.view) {
                                Text(state.screenTitle)
                            }
                        }
                    } footer: {
                        Text("End of list")
                            .accessibilityIdentifier("footerText")
                    }
                }
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("SwiftUI Screens")
            .navigationBarTitleDisplayMode(.inline)
        }
        .navigationTitle("Screen States")
    }
    
    func search(query: String) {
        if query.isEmpty {
            filteredStates = allStates
        } else {
            filteredStates = allStates.filter {
                $0.screenTitle.localizedStandardContains(query)
            }
        }
    }
}

struct ScreenList_Previews: PreviewProvider {
    static var previews: some View {
        ScreenList(screens: [MockTemplateUserProfileScreenState.self])
    }
}
