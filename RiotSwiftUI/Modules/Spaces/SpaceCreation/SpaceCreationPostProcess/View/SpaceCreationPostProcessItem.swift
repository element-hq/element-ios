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

struct SpaceCreationPostProcessItem: View {
    // MARK: - Properties
    
    let title: String
    let state: SpaceCreationPostProcessTaskState
    
    // MARK: Private
    
    @Environment(\.theme) private var theme: ThemeSwiftUI
    private var tintColor: Color {
        switch state {
        case .none:
            return theme.colors.quinaryContent
        case .started:
            return theme.colors.primaryContent
        case .success:
            return theme.colors.tertiaryContent
        case .failure:
            return theme.colors.alert
        }
    }
    
    // MARK: Public
    
    var body: some View {
        HStack {
            switch state {
            case .none:
                Image(systemName: "circle").renderingMode(.template).foregroundColor(theme.colors.tertiaryContent)
            case .started:
                ProgressView().progressViewStyle(CircularProgressViewStyle(tint: theme.colors.secondaryContent)).scaleEffect(0.9, anchor: .center)
                Spacer().frame(width: 6)
            case .success:
                Image(systemName: "checkmark.circle.fill").renderingMode(.template).foregroundColor(theme.colors.tertiaryContent)
            case .failure:
                Image(systemName: "exclamationmark.circle.fill").renderingMode(.template).foregroundColor(theme.colors.alert)
            }
            Text(title)
                .font(theme.fonts.callout)
                .foregroundColor(state == .started ? theme.colors.primaryContent : theme.colors.tertiaryContent)
        }
        .opacity(state == .none ? 0.5 : 1)
        .animation(.easeOut(duration: 0.2), value: state)
    }
}

// MARK: - Previews

struct SpaceCreationPostProcessItem_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            VStack(alignment: .leading, spacing: 20) {
                SpaceCreationPostProcessItem(title: "failed task", state: .failure)
                SpaceCreationPostProcessItem(title: "not started", state: .none)
                SpaceCreationPostProcessItem(title: "on going task ", state: .started)
                SpaceCreationPostProcessItem(title: "succesful task", state: .success)
            }
            VStack(alignment: .leading, spacing: 20) {
                SpaceCreationPostProcessItem(title: "failed task", state: .failure)
                SpaceCreationPostProcessItem(title: "not started", state: .none)
                SpaceCreationPostProcessItem(title: "on going task ", state: .started)
                SpaceCreationPostProcessItem(title: "succesful task", state: .success)
            }.theme(.dark).preferredColorScheme(.dark)
        }
        .padding()
    }
}
