//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import UIKit

class VoiceMessageWaveformView: UIView {

    private let lineWidth: CGFloat = 2.0
    private let linePadding: CGFloat = 2.0
    private let renderingQueue: DispatchQueue = DispatchQueue(label: "io.element.VoiceMessageWaveformView.queue", qos: .userInitiated)

    var samples: [Float] = [] {
        didSet {
            computeWaveForm()
        }
    }
    
    var primaryLineColor = UIColor.lightGray {
        didSet {
            backgroundLayer.strokeColor = primaryLineColor.cgColor
            backgroundLayer.fillColor = primaryLineColor.cgColor
        }
    }
    var secondaryLineColor = UIColor.darkGray {
        didSet {
            progressLayer.strokeColor = secondaryLineColor.cgColor
            progressLayer.fillColor = secondaryLineColor.cgColor
        }
    }

    private let backgroundLayer = CAShapeLayer()
    private let progressLayer = CAShapeLayer()

    var progress = 0.0 {
        didSet {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            progressLayer.frame = CGRect(origin: self.bounds.origin, size: CGSize(width: self.bounds.width * CGFloat(self.progress), height: self.bounds.height))
            CATransaction.commit()
        }
    }

    var requiredNumberOfSamples: Int {
        return Int(self.bounds.size.width / (lineWidth + linePadding))
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupAndAdd(backgroundLayer, with: primaryLineColor)
        setupAndAdd(progressLayer, with: secondaryLineColor)
        progressLayer.masksToBounds = true

        computeWaveForm()
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        
        backgroundLayer.frame = self.bounds
        progressLayer.frame = CGRect(origin: self.bounds.origin, size: CGSize(width: self.bounds.width * CGFloat(self.progress), height: self.bounds.height))
        computeWaveForm()
    }
    
    // MARK: - Private

    private func computeWaveForm() {
        renderingQueue.async { [samples] in // Capture the current samples as a way to provide atomicity
            let path = UIBezierPath()

            let drawMappingFactor = self.bounds.size.height
            let minimumGraphAmplitude: CGFloat = 1

            var xOffset: CGFloat = self.lineWidth / 2
            var index = 0
            
            while xOffset < self.bounds.width - self.lineWidth {
                let sample = CGFloat(index >= samples.count ? 1 : samples[index])
                let invertedDbSample = 1 - sample // sample is in dB, linearly normalized to [0, 1] (1 -> -50 dB)
                let drawingAmplitude = max(minimumGraphAmplitude, invertedDbSample * drawMappingFactor)

                path.move(to: CGPoint(x: xOffset, y: self.bounds.midY - drawingAmplitude / 2))
                path.addLine(to: CGPoint(x: xOffset, y: self.bounds.midY + drawingAmplitude / 2))

                xOffset += self.lineWidth + self.linePadding

                index += 1
            }

            DispatchQueue.main.async {
                self.backgroundLayer.path = path.cgPath
                self.progressLayer.path = path.cgPath
            }
        }
    }
    
    private func setupAndAdd(_ shapeLayer: CAShapeLayer, with color: UIColor) {
        shapeLayer.frame = self.bounds
        shapeLayer.strokeColor = color.cgColor
        shapeLayer.fillColor = color.cgColor
        shapeLayer.lineCap = .round
        shapeLayer.lineWidth = lineWidth
        self.layer.addSublayer(shapeLayer)
    }
}
