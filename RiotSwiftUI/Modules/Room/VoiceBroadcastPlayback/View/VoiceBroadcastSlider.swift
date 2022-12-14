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

/// Customized UISlider for SwiftUI.

struct VoiceBroadcastSlider: UIViewRepresentable {
    @Binding var value: Float
    
    var minValue: Float = 0.0
    var maxValue: Float = 1.0
    var onEditingChanged : ((Bool) -> Void)?
    
    func makeUIView(context: Context) -> UISlider {
        let slider = UISlider(frame: .zero)
        slider.setThumbImage(Asset.Images.voiceBroadcastSliderThumb.image, for: .normal)
        slider.setMinimumTrackImage(Asset.Images.voiceBroadcastSliderMinTrack.image, for: .normal)
        slider.setMaximumTrackImage(Asset.Images.voiceBroadcastSliderMaxTrack.image, for: .normal)
        slider.minimumValue = Float(minValue)
        slider.maximumValue = Float(maxValue)
        slider.value = Float(value)
        slider.addTarget(context.coordinator, action: #selector(Coordinator.valueChanged(_:)), for: .valueChanged)
        slider.addTarget(context.coordinator, action: #selector(Coordinator.sliderEditingChanged(_:)), for: .touchUpInside)
        slider.addTarget(context.coordinator, action: #selector(Coordinator.sliderEditingChanged(_:)), for: .touchUpOutside)
        slider.addTarget(context.coordinator, action: #selector(Coordinator.sliderEditingChanged(_:)), for: .touchDown)

        return slider
    }
    
    func updateUIView(_ uiView: UISlider, context: Context) {
        uiView.value = Float(value)
    }
    
    func makeCoordinator() -> VoiceBroadcastSlider.Coordinator {
        Coordinator(parent: self, value: $value)
    }
    
    class Coordinator: NSObject {
        var parent: VoiceBroadcastSlider
        var value: Binding<Float>
        
        init(parent: VoiceBroadcastSlider, value: Binding<Float>) {
            self.value = value
            self.parent = parent
        }
        
        @objc func valueChanged(_ sender: UISlider) {
            self.value.wrappedValue = sender.value
        }
        
        @objc func sliderEditingChanged(_ sender: UISlider) {
            parent.onEditingChanged?(sender.isTracking)
        }
    }
}
