//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct UIKitTextInputConfiguration {
    var keyboardType: UIKeyboardType = .default
    var returnKeyType: UIReturnKeyType = .default
    var isSecureTextEntry = false
    var autocapitalizationType: UITextAutocapitalizationType = .sentences
    var autocorrectionType: UITextAutocorrectionType = .default
}

struct ThemableTextField: UIViewRepresentable {
    // MARK: Properties
    
    @State var placeholder: String?
    @Binding var text: String
    @State var configuration = UIKitTextInputConfiguration()
    @Binding var isSecureTextVisible: Bool
    var onEditingChanged: ((_ edit: Bool) -> Void)?
    var onCommit: (() -> Void)?

    // MARK: Private
    
    @Environment(\.theme) private var theme: ThemeSwiftUI

    private let textField = UITextField()
    private let internalParams = InternalParams()
    
    // MARK: Setup
    
    init(placeholder: String? = nil,
         text: Binding<String>,
         configuration: UIKitTextInputConfiguration = UIKitTextInputConfiguration(),
         isSecureTextVisible: Binding<Bool> = .constant(false),
         onEditingChanged: ((_ edit: Bool) -> Void)? = nil,
         onCommit: (() -> Void)? = nil) {
        _text = text
        _placeholder = State(initialValue: placeholder)
        _configuration = State(initialValue: configuration)
        _isSecureTextVisible = isSecureTextVisible
        self.onEditingChanged = onEditingChanged
        self.onCommit = onCommit

        ResponderManager.register(view: textField)
    }
    
    // MARK: UIViewRepresentable
    
    func makeUIView(context: Context) -> UITextField {
        textField.delegate = context.coordinator
        textField.setContentHuggingPriority(.defaultHigh, for: .vertical)
        textField.setContentHuggingPriority(.defaultLow, for: .horizontal)
        textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textField.text = text
        
        textField.addTarget(context.coordinator, action: #selector(Coordinator.textFieldEditingChanged(sender:)), for: .editingChanged)
                
        if internalParams.isFirstResponder {
            textField.becomeFirstResponder()
        }

        return textField
    }
    
    func updateUIView(_ uiView: UITextField, context: Context) {
        uiView.backgroundColor = .clear
        uiView.font = UIFont.preferredFont(forTextStyle: .callout)
        uiView.textColor = UIColor(theme.colors.primaryContent)
        uiView.tintColor = UIColor(theme.colors.accent)

        if uiView.text != text {
            uiView.text = text
        }
        uiView.placeholder = placeholder
        
        uiView.keyboardType = configuration.keyboardType
        uiView.returnKeyType = configuration.returnKeyType
        uiView.isSecureTextEntry = configuration.isSecureTextEntry ? !isSecureTextVisible : false
        uiView.autocapitalizationType = configuration.autocapitalizationType
        uiView.autocorrectionType = configuration.autocorrectionType
    }
    
    static func dismantleUIView(_ uiView: UITextField, coordinator: Coordinator) {
        ResponderManager.unregister(view: uiView)
    }

    // MARK: - Private
    
    private func replaceText(with newText: String) {
        text = newText
    }
    
    // MARK: - Coordinator
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: ThemableTextField

        init(_ parent: ThemableTextField) {
            self.parent = parent
        }
        
        func textFieldDidBeginEditing(_ textField: UITextField) {
            parent.onEditingChanged?(true)
        }
        
        func textFieldDidEndEditing(_ textField: UITextField) {
            parent.onEditingChanged?(false)
        }
        
        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            if parent.configuration.returnKeyType != .next || !ResponderManager.makeActiveNextResponder(of: textField) {
                textField.resignFirstResponder()
            }
            
            parent.onCommit?()
            
            return true
        }
        
        @objc func textFieldEditingChanged(sender: UITextField) {
            parent.replaceText(with: sender.text ?? "")
        }
    }
    
    private class InternalParams {
        var isFirstResponder = false
    }
}

// MARK: - modifiers

extension ThemableTextField {
    func makeFirstResponder() -> ThemableTextField {
        makeFirstResponder(true)
    }
    
    func makeFirstResponder(_ isFirstResponder: Bool) -> ThemableTextField {
        internalParams.isFirstResponder = isFirstResponder
        return self
    }
    
    /// Adds a button button to the text field
    /// - Parameters:
    ///   - show: A boolean that can be used to dynamically show/hide the button. Defaults to `true`.
    ///   - alignment: The vertical alignment of the button in the text field. Default to `center`
    @ViewBuilder
    func addButton(_ show: Bool, alignment: VerticalAlignment = .center) -> some View {
        if show, configuration.isSecureTextEntry {
            modifier(PasswordButtonModifier(text: text,
                                            isSecureTextVisible: $isSecureTextVisible,
                                            alignment: alignment))
        } else if show {
            modifier(ClearViewModifier(alignment: alignment,
                                       text: $text))
        } else {
            self
        }
    }
}
