//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.

import SwiftUI

struct ScreenList: View {
    private let allStates: [ScreenStateInfo]
    
    @State private var searchQuery = ""
    @State private var filteredStates: [ScreenStateInfo]
    
    init(screens: [MockScreenState.Type]) {
        let states = screens
            // swiftformat:disable:next preferKeyPath
            .map { $0.stateRenderer }
            .flatMap(\.states)
        
        allStates = states
        filteredStates = states
    }
    
    var body: some View {
        NavigationView {
            VStack {
                TextField("Search", text: $searchQuery)
                    .textFieldStyle(.roundedBorder)
                    .autocorrectionDisabled()
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
