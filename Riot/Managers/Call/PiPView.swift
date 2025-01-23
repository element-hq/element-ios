// 
// Copyright 2020-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import UIKit

@objc enum PiPViewPosition: Int {
    case bottomLeft
    case bottomRight    //  default value
    case topRight
    case topLeft
}

@objc protocol PiPViewDelegate: AnyObject {
    @objc optional func pipView(_ view: PiPView, didMoveTo position: PiPViewPosition)
    @objc optional func pipViewDidTap(_ view: PiPView)
}

@objcMembers
class PiPView: UIView {
    
    private enum Defaults {
        static let margins: UIEdgeInsets = UIEdgeInsets(top: 64, left: 20, bottom: 64, right: 20)
        static let cornerRadius: CGFloat = 8
        static let animationDuration: TimeInterval = 0.25
    }
    
    var margins: UIEdgeInsets = Defaults.margins {
        didSet {
            guard self.superview != nil else { return }
            self.move(to: self.position, animated: true)
        }
    }
    var cornerRadius: CGFloat = Defaults.cornerRadius {
        didSet {
            layer.cornerRadius = cornerRadius
        }
    }
    var position: PiPViewPosition = .bottomRight
    weak var delegate: PiPViewDelegate?
    
    private var originalCenter: CGPoint = .zero
    private var isMoving: Bool = false
    private lazy var tapGestureRecognizer: UITapGestureRecognizer = {
        return UITapGestureRecognizer(target: self, action: #selector(tapped(_:)))
    }()
    private lazy var panGestureRecognizer: UIPanGestureRecognizer = {
        return UIPanGestureRecognizer(target: self, action: #selector(panned(_:)))
    }()
    private var rotationObserver: NSObjectProtocol?
    
    init() {
        super.init(frame: .zero)
        setup()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    var contentView: UIView? {
        willSet {
            if let contentView = contentView {
                //  restore properties of old content view
                contentView.isUserInteractionEnabled = true
            }
        } didSet {
            if let contentView = contentView {
                contentView.isUserInteractionEnabled = false
                addSubview(contentView)
NSLayoutConstraint.activate([
                    contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
                    contentView.trailingAnchor.constraint(equalTo: trailingAnchor),
                    contentView.topAnchor.constraint(equalTo: topAnchor),
                    contentView.bottomAnchor.constraint(equalTo: bottomAnchor)
                ])
            }
        }
    }
    
    func move(in view: UIView? = nil,
              to position: PiPViewPosition = .bottomRight,
              targetSize: CGSize? = nil,
              animated: Bool = false,
              completion: ((Bool) -> Void)? = nil) {
        
        let block = {
            let targetFrame = self.targetFrame(for: position, in: view, targetSize: targetSize)
            self.frame = targetFrame
        }
        
        if animated {
            UIView.animate(withDuration: Defaults.animationDuration, animations: block) { (completed) in
                self.position = position
                completion?(completed)
            }
        } else {
            block()
            self.position = position
            completion?(true)
        }
    }
    
    deinit {
        if let rotationObserver = rotationObserver {
            NotificationCenter.default.removeObserver(rotationObserver)
        }
    }
    
    //  MARK: - Private
    
    private func setup() {
        isUserInteractionEnabled = true
        clipsToBounds = true
        layer.cornerRadius = cornerRadius
        addGestureRecognizer(tapGestureRecognizer)
        addGestureRecognizer(panGestureRecognizer)
        rotationObserver = NotificationCenter.default.addObserver(forName: UIDevice.orientationDidChangeNotification, object: nil, queue: nil) { [weak self] (_) in
            guard let self = self else { return }
            guard self.superview != nil else { return }
            self.move(to: self.position, animated: true)
        }
    }
    
    private func targetFrame(for position: PiPViewPosition,
                             in view: UIView?,
                             targetSize: CGSize?) -> CGRect {
        guard let view = view ?? superview else {
            return .zero
        }
        let targetSize = targetSize ?? frame.size
        
        var superviewWidth: CGFloat = 0
        var superviewHeight: CGFloat = 0
        
        if UIDevice.current.orientation.isPortrait {
            superviewWidth = min(view.bounds.width, view.bounds.height)
            superviewHeight = max(view.bounds.width, view.bounds.height)
        } else {
            superviewWidth = max(view.bounds.width, view.bounds.height)
            superviewHeight = min(view.bounds.width, view.bounds.height)
        }
        
        switch position {
        case .bottomLeft:
            let origin = CGPoint(x: margins.left + view.safeAreaInsets.left,
                                 y: superviewHeight - view.safeAreaInsets.bottom - targetSize.height - margins.bottom)
            return CGRect(origin: origin,
                          size: targetSize)
        case .bottomRight:
            let origin = CGPoint(x: superviewWidth - view.safeAreaInsets.right - margins.right - targetSize.width,
                                 y: superviewHeight - view.safeAreaInsets.bottom - targetSize.height - margins.bottom)
            return CGRect(origin: origin,
                          size: targetSize)
        case .topRight:
            let origin = CGPoint(x: superviewWidth - view.safeAreaInsets.right - margins.right - targetSize.width,
                                 y: margins.top + view.safeAreaInsets.top)
            return CGRect(origin: origin,
                          size: targetSize)
        case .topLeft:
            let origin = CGPoint(x: margins.left + view.safeAreaInsets.left,
                                 y: margins.top + view.safeAreaInsets.top)
            return CGRect(origin: origin,
                          size: targetSize)
        }
    }
    
    @objc private func tapped(_ sender: UITapGestureRecognizer) {
        delegate?.pipViewDidTap?(self)
    }
    
    @objc private func panned(_ sender: UIPanGestureRecognizer) {
        switch sender.state {
        case .possible:
            isMoving = false
        case .began:
            originalCenter = center
            isMoving = true
        case .changed:
            let translation = sender.translation(in: superview)
            
            if isMoving {
                center = CGPoint(x: originalCenter.x + translation.x,
                                 y: originalCenter.y + translation.y)
            }
        case .ended:
            defer {
                isMoving = false
            }
            
            if isMoving {
                guard let superview = self.superview else { return }
                
                let translation = sender.translation(in: superview)
                
                let bounds = superview.bounds
                let midX = bounds.width / 2
                let midY = bounds.height / 2
                
                let onLeftHalf = originalCenter.x + translation.x < midX
                let onTopHalf = originalCenter.y + translation.y < midY
                
                var newPosition: PiPViewPosition = .bottomLeft
                
                if onLeftHalf {
                    if onTopHalf {
                        newPosition = .topLeft
                    } else {
                        newPosition = .bottomLeft
                    }
                } else {
                    if onTopHalf {
                        newPosition = .topRight
                    } else {
                        newPosition = .bottomRight
                    }
                }
                
                move(to: newPosition) { (_) in
                    self.delegate?.pipView?(self, didMoveTo: newPosition)
                }
            }
        case .cancelled:
            isMoving = false
        case .failed:
            isMoving = false
        @unknown default:
            isMoving = false
        }
    }
    
}
