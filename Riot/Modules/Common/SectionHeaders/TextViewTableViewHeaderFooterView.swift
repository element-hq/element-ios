// 
// Copyright 2020-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import Reusable

protocol TextViewTableViewHeaderFooterViewDelegate: UITextViewDelegate {
    
}

class TextViewTableViewHeaderFooterView: UITableViewHeaderFooterView {
    
    // MARK - Private
    private var _textView: UITextView?
    
    private var textViewLeftConstraint: NSLayoutConstraint?
    private var textViewTopConstraint: NSLayoutConstraint?
    private var textViewRightConstraint: NSLayoutConstraint?
    private var textViewBottomConstraint: NSLayoutConstraint?
    
    // MARK - Public
    
    weak var delegate: TextViewTableViewHeaderFooterViewDelegate?
    
    var textViewInsets: UIEdgeInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16) {
        didSet {
            setNeedsUpdateConstraints()
        }
    }
    
    /// Will be created if accessed
    var textView: UITextView {
        //  hide text label if textView accessed
        textLabel?.isHidden = true
        
        if let _textView = _textView {
            return _textView
        }
        
        let view = UITextView()
        view.backgroundColor = .clear
        view.translatesAutoresizingMaskIntoConstraints = false
        view.delegate = self
        view.isEditable = false
        view.isScrollEnabled = false
        view.scrollsToTop = false
        view.textContainerInset = .zero
        view.contentInset = .zero
        view.textContainer.lineFragmentPadding = 0
        contentView.addSubview(view)
        textViewLeftConstraint = view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: textViewInsets.left)
        textViewTopConstraint = view.topAnchor.constraint(equalTo: contentView.topAnchor, constant: textViewInsets.top)
        textViewRightConstraint = contentView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: textViewInsets.right)
        textViewBottomConstraint = contentView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: textViewInsets.bottom)
        textViewLeftConstraint?.isActive = true
        textViewTopConstraint?.isActive = true
        textViewRightConstraint?.isActive = true
        textViewBottomConstraint?.isActive = true
        _textView = view
        return view
    }
    
    override func updateConstraints() {
        super.updateConstraints()
        
        textViewLeftConstraint?.constant = textViewInsets.left
        textViewTopConstraint?.constant = textViewInsets.top
        textViewRightConstraint?.constant = textViewInsets.right
        textViewBottomConstraint?.constant = textViewInsets.bottom
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        textViewInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
    }
    
}

extension TextViewTableViewHeaderFooterView: Reusable { }

extension TextViewTableViewHeaderFooterView: Themable {
    
    func update(theme: Theme) {
        contentView.backgroundColor = theme.headerBackgroundColor
        textLabel?.textColor = theme.textSecondaryColor
        _textView?.textColor = theme.textSecondaryColor
        _textView?.linkTextAttributes = [NSAttributedString.Key.foregroundColor: theme.tintColor]
    }
    
}

extension TextViewTableViewHeaderFooterView: UITextViewDelegate {
    
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        return delegate?.textView?(textView, shouldInteractWith: URL, in: characterRange, interaction: interaction) ?? (interaction == .invokeDefaultAction)
    }
    
    func textViewDidChangeSelection(_ textView: UITextView) {
        return delegate?.textViewDidChangeSelection?(textView) ?? {
            textView.selectedRange = NSRange(location: 0, length: 0)
            }()
    }
    
}
