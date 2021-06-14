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

import UIKit

class VoiceMessageWaveformView: UIView {

    private let lineWidth: CGFloat = 2.0
    private let primarylineColor = UIColor.lightGray
    private let secondaryLineColor = UIColor.darkGray
    private let linePadding: CGFloat = 2.0

    private var samples: [Float] = []
    private var barViews: [CALayer] = []
    
    var progress = 0.0 {
        didSet {
            updateBarViews()
        }
    }

    var requiredNumberOfSamples: Int {
        return barViews.count
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupBarViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        setupBarViews()
    }
    
    func setSamples(_ samples: [Float]) {
        self.samples = samples
        updateBarViews()
    }

    func addSample(_ sample: Float) {
        samples.append(sample)
        updateBarViews()
    }

    // MARK: - Private

    private func setupBarViews() {
        for layer in barViews {
            layer.removeFromSuperlayer()
        }

        var barViews: [CALayer] = []

        var xOffset: CGFloat = lineWidth / 2

        while xOffset < bounds.width - lineWidth {
            let layer = CALayer()
            layer.backgroundColor = primarylineColor.cgColor
            layer.cornerRadius = lineWidth / 2
            layer.masksToBounds = true
            layer.anchorPoint = CGPoint(x: 0, y: 0.5)
            layer.frame = CGRect(x: xOffset, y: bounds.midY - lineWidth / 2, width: lineWidth, height: lineWidth)

            self.layer.addSublayer(layer)

            barViews.append(layer)

            xOffset += lineWidth + linePadding
        }

        self.barViews = barViews

        updateBarViews()
    }

    private func updateBarViews() {
        let drawMappingFactor = bounds.size.height
        let minimumGraphAmplitude: CGFloat = lineWidth
        
        let progressPosition = Int(floor(progress * Double(barViews.count)))
        
        for (index, layer) in barViews.enumerated() {
            let sample = CGFloat(index >= samples.count ? 1 : samples[index])
            
            let invertedDbSample = 1 - sample // sample is in dB, linearly normalized to [0, 1] (1 -> -50 dB)
            let drawingAmplitude = max(minimumGraphAmplitude, invertedDbSample * drawMappingFactor)
            
            layer.frame.origin.y = bounds.midY - drawingAmplitude / 2
            layer.frame.size.height = drawingAmplitude
            
            layer.backgroundColor = (index < progressPosition ? secondaryLineColor.cgColor : primarylineColor.cgColor)   
        }
    }
}
