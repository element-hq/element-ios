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
import SceneKit

/// A SwiftUI wrapper around `SCNView`, that unlike `SceneView` allows the
/// scene to have a transparent background and be rendered on top of other views.
struct EffectsView: UIViewRepresentable {
    
    // MARK: - Private
    
    @Environment(\.theme) private var theme
    
    // MARK: - Public
    
    enum Effect {
        /// A confetti drop effect from the top centre of the screen.
        case confetti
        /// No effect will be shown.
        case none
    }
    
    /// The type of effects to be shown in the view.
    var effect: Effect
    
    // MARK: - Lifecycle
    
    func makeUIView(context: Context) -> SCNView {
        SCNView(frame: .zero)
    }
    
    func updateUIView(_ sceneView: SCNView, context: Context) {
        sceneView.scene = makeScene()
        sceneView.backgroundColor = .clear
    }
    
    // MARK: - Private
    
    private func makeScene() -> EffectsScene? {
        switch effect {
        case .confetti:
            return EffectsScene.confetti(with: theme)
        case .none:
            return nil
        }
    }
}

struct EffectsView_Previews: PreviewProvider {
    static var previews: some View {
        EffectsView(effect: .confetti)
    }
}
