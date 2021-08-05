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

import SwiftUI

@available(iOS 13.0, *)
struct VectorForm<Content: View>: View {
    
    @Environment(\.theme) var theme: Theme
    var content: () -> Content
    
    var body: some View {
        List(content: content)
        .listRowBackground(Color(theme.backgroundColor))
        .listStyle(GroupedListStyle())
        .onAppear {
            UITableView.appearance().backgroundColor = theme.baseColor
            UINavigationBar.appearance().barTintColor = theme.baseColor
            UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: theme.textPrimaryColor]
            UINavigationBar.appearance().isTranslucent = false
            UINavigationBar.appearance().setBackgroundImage(UIImage(), for: UIBarMetrics.default)
            UINavigationBar.appearance().shadowImage = UIImage()
        }
    }
}

@available(iOS 13.0, *)
struct VectorForm_Previews: PreviewProvider {
    static var previews: some View {
        VectorForm {
            Text("Item 1")
        }
    }
}
