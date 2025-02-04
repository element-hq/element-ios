//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SceneKit
import SwiftUI

class EffectsScene: SCNScene {
    // MARK: - Constants
    
    private enum Constants {
        static let confettiSceneName = "ConfettiScene.scn"
        static let particlesNodeName = "particles"
    }
    
    // MARK: - Public
    
    static func confetti(with theme: ThemeSwiftUI) -> EffectsScene? {
        guard let scene = EffectsScene(named: Constants.confettiSceneName) else { return nil }
        
        let colors: [[Float]] = theme.colors.namesAndAvatars.compactMap(\.floatComponents)
        
        if let particles = scene.rootNode.childNode(withName: Constants.particlesNodeName, recursively: false)?.particleSystems?.first {
            // The particles need a non-zero color variation for the handler to affect the color
            particles.particleColorVariation = SCNVector4(x: 0, y: 0, z: 0, w: 0.1)
            
            // Add a handler to customize the color of the particles.
            particles.handle(.birth, forProperties: [.color]) { data, dataStride, _, count in
                for index in 0..<count {
                    // Pick a random color to apply to the particle.
                    guard let color = colors.randomElement() else { continue }
                    
                    // Get the particle's color pointer.
                    let colorPointer = data[0] + dataStride[0] * index
                    let rgbaPointer = colorPointer.bindMemory(to: Float.self, capacity: dataStride[0])
                    
                    // Update the color for the particle.
                    rgbaPointer[0] = color[0]
                    rgbaPointer[1] = color[1]
                    rgbaPointer[2] = color[2]
                    rgbaPointer[3] = 1
                }
            }
        }
        
        return scene
    }
}

private extension Color {
    /// The color's components as an array of floats in the extended linear sRGB colorspace.
    ///
    /// SceneKit works in a colorspace with a linear gamma, which is why this conversion is necessary.
    var floatComponents: [Float]? {
        // Get the CGColor from a UIColor as it is nil on Color when loaded from an asset catalog.
        let cgColor = UIColor(self).cgColor
        
        guard
            let colorSpace = CGColorSpace(name: CGColorSpace.extendedLinearSRGB),
            let linearColor = cgColor.converted(to: colorSpace, intent: .defaultIntent, options: nil),
            let components = linearColor.components
        else { return nil }
        
        return components.map { Float($0) }
    }
}
