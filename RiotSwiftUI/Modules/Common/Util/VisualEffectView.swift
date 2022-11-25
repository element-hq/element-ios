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

@available(iOS 14.0, *)
struct VisualEffectView: UIViewRepresentable {
    var effect: UIVisualEffect?
//    var intensity: CGFloat = 1
    
    func makeUIView(context: UIViewRepresentableContext<Self>) -> UIVisualEffectView { UIVisualEffectView() }
    func updateUIView(_ uiView: UIVisualEffectView, context: UIViewRepresentableContext<Self>) {
//        let interpolateAnimation = Interpolate(from: 0, to: intensity) { (destination) in
//            self.animator.fractionComplete = CGFloat(destination)
//            print(self.animator.fractionComplete)
//        }
//        interpolateAnimation.animate(duration: 0.3)
//        uiView.intensity = intensity
        uiView.effect = effect
    }
}

private class CustomIntensityVisualEffectView: UIVisualEffectView {

//    /// Create visual effect view with given effect and its intensity
//    ///
//    /// - Parameters:
//    ///   - effect: visual effect, eg UIBlurEffect(style: .dark)
//    ///   - intensity: custom intensity from 0.0 (no effect) to 1.0 (full effect) using linear scale
//    init(effect: UIVisualEffect, intensity: CGFloat) {
//        super.init(effect: nil)
//    }
    
    var intensity: CGFloat
    
    override var effect: UIVisualEffect? {
        get {
            return super.effect
        }
        set {
            animator = UIViewPropertyAnimator(duration: 1, curve: .linear) { super.effect = newValue }
            animator.fractionComplete = intensity
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }

    // MARK: Private
    private var animator: UIViewPropertyAnimator!

}
