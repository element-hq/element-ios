// 
// Copyright 2020 New Vector Ltd
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
