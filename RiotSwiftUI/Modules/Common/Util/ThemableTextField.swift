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

import SwiftUI

struct UIKitTextInputConfiguration {
    var keyboardType: UIKeyboardType = .default
    var returnKeyType: UIReturnKeyType = .default
    var isSecureTextEntry: Bool = false
    var autocapitalizationType: UITextAutocapitalizationType = .sentences
    var autocorrectionType: UITextAutocorrectionType = .default
}

struct ThemableTextField: UIViewRepresentable {
    
    // MARK: Properties
    
    @State var placeholder: String?
    @Binding var text: String
    @State var configuration: UIKitTextInputConfiguration = UIKitTextInputConfiguration()
    @Binding var isSecureTextVisible: Bool
    var onEditingChanged: ((_ edit: Bool) -> Void)?
    var onCommit: (() -> Void)?

    // MARK: Private
    
    @Environment(\.theme) private var theme: ThemeSwiftUI

    private let textField: UITextField = UITextField()
    private let internalParams = InternalParams()
    
    // MARK: Setup
    
    init(placeholder: String? = nil,
         text: Binding<String>,
         configuration: UIKitTextInputConfiguration = UIKitTextInputConfiguration(),
         isSecureTextVisible: Binding<Bool> = .constant(false),
         onEditingChanged: ((_ edit: Bool) -> Void)? = nil,
         onCommit: (() -> Void)? = nil) {
        self._text = text
        self._placeholder = State(initialValue: placeholder)
        self._configuration = State(initialValue: configuration)
        self._isSecureTextVisible = isSecureTextVisible
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

        if uiView.text != self.text {
            uiView.text = self.text
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
        self.text = newText
    }
    
    // MARK: - Coordinator
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
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
        return makeFirstResponder(true)
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
        if show && configuration.isSecureTextEntry {
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
