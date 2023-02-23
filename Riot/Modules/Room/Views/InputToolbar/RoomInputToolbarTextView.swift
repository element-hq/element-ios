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

@objc protocol RoomInputToolbarTextViewDelegate: AnyObject {
    func textView(_ textView: RoomInputToolbarTextView, didChangeHeight height: CGFloat)
    func textView(_ textView: RoomInputToolbarTextView, didReceivePasteForMediaFromSender sender: Any?)
}

@objcMembers
class RoomInputToolbarTextView: UITextView {
    
    private var heightConstraint: NSLayoutConstraint!
        
    weak var toolbarDelegate: RoomInputToolbarTextViewDelegate?
        
    var placeholder: String? {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var placeholderColor: UIColor = UIColor(white: 0.8, alpha: 1.0) {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var minHeight: CGFloat = 30.0 {
        didSet {
            updateUI()
        }
    }
    
    var maxHeight: CGFloat = 0.0 {
        didSet {
            updateUI()
        }
    }
    
    override var text: String! {
        didSet {
            updateUI()
        }
    }

    override var attributedText: NSAttributedString! {
        didSet {
            updateUI()
        }
    }
    
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        contentMode = .redraw
        
        NotificationCenter.default.addObserver(self, selector: #selector(textDidChange), name: UITextView.textDidChangeNotification, object: self)
        
        if let heightConstraint = constraints.filter({ $0.firstAttribute == .height && $0.relation == .equal }).first {
            self.heightConstraint = heightConstraint
        } else {
            heightConstraint = self.heightAnchor.constraint(equalToConstant: minHeight)
            addConstraint(heightConstraint)
        }
    }
    
    // MARK: - Overrides
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateUI()
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        guard attributedText.length == 0, let placeholder = placeholder else {
            return
        }
        
        var attributes: [NSAttributedString.Key: Any] = [.foregroundColor: placeholderColor]
        if let font = font {
            attributes[.font] = font
        }
        
        let frame = rect.inset(by: .init(top: textContainerInset.top,
                                         left: textContainerInset.left + textContainer.lineFragmentPadding,
                                         bottom: textContainerInset.bottom,
                                         right: textContainerInset.right))
        
        placeholder.draw(in: frame, withAttributes: attributes)
    }
    
    override var keyCommands: [UIKeyCommand]? {
        return [UIKeyCommand(input: "\r", modifierFlags: [], action: #selector(keyCommandSelector(_:)))]
    }
    
    /// Overrides paste to handle images pasted from Safari, passing them up to the input toolbar.
    /// This is required as the pasteboard contains both the image and the image's URL, with the
    /// default implementation choosing to paste the URL and completely ignore the image data.
    override func paste(_ sender: Any?) {
        let pasteboard = MXKPasteboardManager.shared.pasteboard
        let types = pasteboard.types.map { UTI(rawValue: $0) }
        
        if types.contains(where: { $0.conforms(to: .image) }) {
            toolbarDelegate?.textView(self, didReceivePasteForMediaFromSender: sender)
        } else {
            super.paste(sender)
        }
    }
    
    // MARK: - Private

    @objc private func textDidChange(notification: Notification) {
        if let sender = notification.object as? RoomInputToolbarTextView, sender == self {
            updateUI()
        }
    }
    
    private func updateUI() {
        var height = contentSize.height
        height = minHeight > 0 ? max(height, minHeight) : height
        height = maxHeight > 0 ? min(height, maxHeight) : height
        
        // Update placeholder
        self.setNeedsDisplay()
        
        guard height != heightConstraint.constant else {
            return
        }
        
        heightConstraint.constant = height
        toolbarDelegate?.textView(self, didChangeHeight: height)
    }
    
    @objc private func keyCommandSelector(_ keyCommand: UIKeyCommand) {
        guard keyCommand.input == "\r", let delegate = (self.delegate as? RoomInputToolbarView) else {
            return
        }
        
        delegate.onTouchUp(inside: delegate.rightInputToolbarButton)
    }
}
