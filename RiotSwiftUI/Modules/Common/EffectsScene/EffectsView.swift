//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SceneKit
import SwiftUI

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
