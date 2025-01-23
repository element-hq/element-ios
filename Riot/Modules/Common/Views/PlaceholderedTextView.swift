// 
// Copyright 2020-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import UIKit

class PlaceholderedTextView: UITextView {
    
    private var kvoLineFragmentPadding: NSKeyValueObservation?
    private lazy var placeholderTextView: UITextView = {
        let view = UITextView()
        view.contentInset = self.contentInset
        view.textContainerInset = self.textContainerInset
        view.textContainer.lineFragmentPadding = self.textContainer.lineFragmentPadding
        view.scrollsToTop = false
        view.showsVerticalScrollIndicator = false
        view.showsHorizontalScrollIndicator = false
        view.isEditable = false
        view.isSelectable = false
        view.isScrollEnabled = false
        view.textColor = self.placeholderColor
        if let placeholder = self.placeholder {
            view.text = placeholder
        } else if let attributedPlaceholder = self.attributedPlaceholder {
            view.attributedText = attributedPlaceholder
        }
        view.backgroundColor = .clear
        view.tintColor = .clear
        self.addSubview(view)
        self.sendSubviewToBack(view)
        return view
    }()
    
    var placeholder: String? {
        didSet {
            placeholderTextView.text = placeholder
        }
    }
    var attributedPlaceholder: NSAttributedString? {
        didSet {
            placeholderTextView.attributedText = attributedPlaceholder
        }
    }
    var placeholderColor: UIColor = .lightGray {
        didSet {
            placeholderTextView.textColor = placeholderColor
        }
    }
    
    override var font: UIFont? {
        didSet {
            placeholderTextView.font = font
        }
    }
    
    override var contentInset: UIEdgeInsets {
        didSet {
            placeholderTextView.contentInset = contentInset
        }
    }
    
    override var textContainerInset: UIEdgeInsets {
        didSet {
            placeholderTextView.textContainerInset = textContainerInset
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        placeholderTextView.frame = bounds
    }
    
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        NotificationCenter.default.addObserver(self, selector: #selector(textViewTextChanged(_:)), name: UITextView.textDidChangeNotification, object: self)
        kvoLineFragmentPadding = observe(\.textContainer.lineFragmentPadding, options: [.new]) { [weak self] (_, change) in
            guard let self = self else { return }
            let newValue = change.newValue ?? 0            
            self.placeholderTextView.textContainer.lineFragmentPadding = newValue
        }
    }

    override var text: String! {
        didSet {
            super.text = text
            updatePlaceholderVisibility()
        }
    }

    @objc func textViewTextChanged(_ sender: UITextView) {
        updatePlaceholderVisibility()
    }

    private func updatePlaceholderVisibility() {
        placeholderTextView.isHidden = text.count > 0
    }
    
}
