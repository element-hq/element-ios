// File created from simpleScreenTemplate
// $ createSimpleScreen.sh Dialpad Dialpad
/*
 Copyright 2020 New Vector Ltd
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

import UIKit
import libPhoneNumber_iOS

@objc protocol DialpadViewControllerDelegate: AnyObject {
    @objc optional func dialpadViewControllerDidTapCall(_ viewController: DialpadViewController,
                                                        withPhoneNumber phoneNumber: String)
    @objc optional func dialpadViewControllerDidTapClose(_ viewController: DialpadViewController)
    
    @objc optional func dialpadViewControllerDidTapDigit(_ viewController: DialpadViewController, digit: String)
}

@objcMembers
class DialpadViewController: UIViewController {
    
    // MARK: Outlets
    
    @IBOutlet private weak var phoneNumberTextFieldTopConstraint: NSLayoutConstraint! {
        didSet {
            if !configuration.showsTitle && !configuration.showsCloseButton {
                phoneNumberTextFieldTopConstraint.constant = 0
            }
        }
    }
    @IBOutlet private weak var closeButton: UIButton! {
        didSet {
            closeButton.isHidden = !configuration.showsCloseButton
        }
    }
    @IBOutlet private weak var titleLabel: UILabel! {
        didSet {
            titleLabel.isHidden = !configuration.showsTitle
        }
    }
    @IBOutlet private weak var phoneNumberTextField: UITextField! {
        didSet {
            phoneNumberTextField.text = nil
            //  avoid showing keyboard on text field
            phoneNumberTextField.inputView = UIView()
            phoneNumberTextField.inputAccessoryView = UIView()
            phoneNumberTextField.isUserInteractionEnabled = configuration.editingEnabled
        }
    }
    @IBOutlet private weak var lineView: UIView!
    @IBOutlet private weak var digitsStackView: UIStackView!
    @IBOutlet private var digitButtons: [DialpadButton]!
    @IBOutlet private weak var backspaceButton: DialpadActionButton! {
        didSet {
            backspaceButton.type = .backspace
            backspaceButton.isHidden = !configuration.showsBackspaceButton
        }
    }
    @IBOutlet private weak var callButton: DialpadActionButton! {
        didSet {
            callButton.type = .call
            callButton.isHidden = !configuration.showsCallButton
        }
    }
    @IBOutlet private weak var spaceButton: UIButton! {
        didSet {
            spaceButton.isHidden = !configuration.showsBackspaceButton || !configuration.showsCallButton
        }
    }
    
    // MARK: Private
    
    private enum Constants {
        static let sizeOniPad: CGSize = CGSize(width: 375, height: 667)
        static let additionalTopInset: CGFloat = 20
        static let digitButtonViewDatas: [Int: DialpadButton.ViewData] = [
            -2: .init(title: "#", tone: 1211),
            -1: .init(title: "*", tone: 1210),
            0: .init(title: "0", tone: 1200, subtitle: "+"),
            1: .init(title: "1", tone: 1201, showsSubtitleSpace: true),
            2: .init(title: "2", tone: 1202, subtitle: "ABC"),
            3: .init(title: "3", tone: 1203, subtitle: "DEF"),
            4: .init(title: "4", tone: 1204, subtitle: "GHI"),
            5: .init(title: "5", tone: 1205, subtitle: "JKL"),
            6: .init(title: "6", tone: 1206, subtitle: "MNO"),
            7: .init(title: "7", tone: 1207, subtitle: "PQRS"),
            8: .init(title: "8", tone: 1208, subtitle: "TUV"),
            9: .init(title: "9", tone: 1209, subtitle: "WXYZ")
        ]
    }
    
    private var wasCursorAtTheEnd: Bool = true
    
    /// Phone number as formatted
    private var phoneNumber: String = "" {
        willSet {
            if configuration.editingEnabled {
                wasCursorAtTheEnd = isCursorAtTheEnd()
            }
        } didSet {
            phoneNumberTextField.text = phoneNumber
            if configuration.editingEnabled && wasCursorAtTheEnd {
                moveCursorToTheEnd()
            }
        }
    }
    /// Phone number as non-formatted
    var rawPhoneNumber: String {
        return phoneNumber.vc_removingAllWhitespaces()
    }
    private var theme: Theme!
    private var configuration: DialpadConfiguration!
    
    // MARK: Public
    
    weak var delegate: DialpadViewControllerDelegate?
    
    // MARK: - Setup
    
    class func instantiate(withConfiguration configuration: DialpadConfiguration = .default) -> DialpadViewController {
        let viewController = StoryboardScene.DialpadViewController.initialScene.instantiate()
        viewController.theme = ThemeService.shared().theme
        viewController.configuration = configuration
        return viewController
    }
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        titleLabel.text = VectorL10n.dialpadTitle
        self.registerThemeServiceDidChangeThemeNotification()
        self.update(theme: self.theme)
        
        //  force orientation to portrait if phone
        if UIDevice.current.isPhone {
            UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
        }
        
        for button in digitButtons {
            if let viewData = Constants.digitButtonViewDatas[button.tag] {
                button.render(withViewData: viewData)
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        AnalyticsScreenTracker.trackScreen(.dialpad)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return self.theme.statusBarStyle
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        //  limit orientation to portrait only for phone
        if UIDevice.current.isPhone {
            return .portrait
        }
        return super.supportedInterfaceOrientations
    }
    
    override var shouldAutorotate: Bool {
        return false
    }
    
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        if UIDevice.current.isPhone {
            return .portrait
        }
        return super.preferredInterfaceOrientationForPresentation
    }
    
    // MARK: - Private
    
    private func isCursorAtTheEnd() -> Bool {
        guard let selectedRange = phoneNumberTextField.selectedTextRange else {
            return true
        }
        
        if !selectedRange.isEmpty {
            return false
        }
        
        let cursorEndPos = phoneNumberTextField.offset(from: phoneNumberTextField.beginningOfDocument, to: selectedRange.end)
        
        return cursorEndPos == phoneNumber.count
    }
    
    private func moveCursorToTheEnd() {
        guard let cursorPos = phoneNumberTextField.position(from: phoneNumberTextField.beginningOfDocument,
                                                            offset: phoneNumber.count) else { return }
        
        phoneNumberTextField.selectedTextRange = phoneNumberTextField.textRange(from: cursorPos,
                                                                                to: cursorPos)
    }
    
    private func reformatPhoneNumber() {
        guard configuration.formattingEnabled, let phoneNumberUtil = NBPhoneNumberUtil.sharedInstance() else {
            //  no formatter
            return
        }
        
        do {
            //  try formatting the number
            if phoneNumber.hasPrefix("00") {
                let range = phoneNumber.startIndex..<phoneNumber.index(phoneNumber.startIndex, offsetBy: 2)
                phoneNumber.replaceSubrange(range, with: "+")
            }
            let nbPhoneNumber = try phoneNumberUtil.parse(rawPhoneNumber, defaultRegion: nil)
            phoneNumber = try phoneNumberUtil.format(nbPhoneNumber, numberFormat: .INTERNATIONAL)
        } catch {
            //  continue without formatting
        }
    }
    
    private func update(theme: Theme) {
        self.theme = theme
        
        self.view.backgroundColor = theme.backgroundColor
        
        if let navigationBar = self.navigationController?.navigationBar {
            theme.applyStyle(onNavigationBar: navigationBar)
        }
        
        if theme.identifier == ThemeIdentifier.light.rawValue {
            titleLabel.textColor = theme.noticeSecondaryColor
            closeButton.setBackgroundImage(Asset.Images.closeButton.image.vc_tintedImage(usingColor: theme.tabBarUnselectedItemTintColor), for: .normal)
        } else {
            titleLabel.textColor = theme.baseTextSecondaryColor
            closeButton.setBackgroundImage(Asset.Images.closeButton.image.vc_tintedImage(usingColor: theme.baseTextSecondaryColor), for: .normal)
        }
        phoneNumberTextField.textColor = theme.textPrimaryColor
        lineView.backgroundColor = theme.lineBreakColor
        
        updateThemesOfAllButtons(in: digitsStackView, with: theme)
    }
    
    private func updateThemesOfAllButtons(in view: UIView, with theme: Theme) {
        if let button = view as? DialpadButton {
            button.update(theme: theme)
        } else {
            for subview in view.subviews {
                updateThemesOfAllButtons(in: subview, with: theme)
            }
        }
    }
    
    private func registerThemeServiceDidChangeThemeNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .themeServiceDidChangeTheme, object: nil)
    }
    
    private func topSafeAreaInset() -> CGFloat {
        guard let window = UIApplication.shared.keyWindow else {
            return Constants.additionalTopInset
        }
        
        return window.safeAreaInsets.top + Constants.additionalTopInset
    }

    // MARK: - Actions
    
    @objc private func themeDidChange() {
        self.update(theme: ThemeService.shared().theme)
    }
    
    @IBAction private func closeButtonAction(_ sender: UIButton) {
        delegate?.dialpadViewControllerDidTapClose?(self)
    }
    
    @IBAction private func digitButtonAction(_ sender: DialpadButton) {
        guard let digitViewData = Constants.digitButtonViewDatas[sender.tag] else {
            return
        }
        let digit = digitViewData.title
        
        defer {
            delegate?.dialpadViewControllerDidTapDigit?(self, digit: digit)
        }
        
        if configuration.playTones {
            AudioServicesPlaySystemSound(digitViewData.tone)
        }
        
        if !configuration.editingEnabled {
            phoneNumber += digit
            return
        }
        
        if let selectedRange = phoneNumberTextField.selectedTextRange {
            if isCursorAtTheEnd() {
                phoneNumber += digit
                reformatPhoneNumber()
                return
            }
            let cursorStartPos = phoneNumberTextField.offset(from: phoneNumberTextField.beginningOfDocument, to: selectedRange.start)
            let cursorEndPos = phoneNumberTextField.offset(from: phoneNumberTextField.beginningOfDocument, to: selectedRange.end)
            
            phoneNumber.replaceSubrange((phoneNumber.index(phoneNumber.startIndex, offsetBy: cursorStartPos))..<(phoneNumber.index(phoneNumber.startIndex, offsetBy: cursorEndPos)), with: digit)
            
            guard let cursorPos = phoneNumberTextField.position(from: phoneNumberTextField.beginningOfDocument,
                                                                offset: cursorEndPos + digit.count) else { return }
            
            reformatPhoneNumber()
            
            phoneNumberTextField.selectedTextRange = phoneNumberTextField.textRange(from: cursorPos,
                                                                                    to: cursorPos)
        } else {
            phoneNumber += digit
            reformatPhoneNumber()
        }
    }
    
    @IBAction private func backspaceButtonAction(_ sender: DialpadActionButton) {
        defer {
            delegate?.dialpadViewControllerDidTapDigit?(self, digit: "")
        }
        
        if phoneNumber.isEmpty {
            return
        }
        
        if !configuration.editingEnabled {
            phoneNumber.removeLast()
            return
        }
        
        if let selectedRange = phoneNumberTextField.selectedTextRange {
            let cursorStartPos = phoneNumberTextField.offset(from: phoneNumberTextField.beginningOfDocument, to: selectedRange.start)
            let cursorEndPos = phoneNumberTextField.offset(from: phoneNumberTextField.beginningOfDocument, to: selectedRange.end)
            
            let rangePos: UITextPosition!
            
            if selectedRange.isEmpty {
                //  just caret, remove one char from the cursor position
                if cursorStartPos == 0 {
                    //  already at the beginning of the text, no more text to remove here
                    return
                }
                phoneNumber.replaceSubrange((phoneNumber.index(phoneNumber.startIndex, offsetBy: cursorStartPos-1))..<(phoneNumber.index(phoneNumber.startIndex, offsetBy: cursorEndPos)), with: "")
                
                rangePos = phoneNumberTextField.position(from: phoneNumberTextField.beginningOfDocument,
                                                         offset: cursorStartPos-1)
            } else {
                //  really some text selected, remove selected range of text
                
                phoneNumber.replaceSubrange((phoneNumber.index(phoneNumber.startIndex, offsetBy: cursorStartPos))..<(phoneNumber.index(phoneNumber.startIndex, offsetBy: cursorEndPos)), with: "")
                
                rangePos = phoneNumberTextField.position(from: phoneNumberTextField.beginningOfDocument,
                                                         offset: cursorStartPos)
            }
            
            reformatPhoneNumber()
            
            guard let cursorPos = rangePos else { return }
            phoneNumberTextField.selectedTextRange = phoneNumberTextField.textRange(from: cursorPos,
                                                                                    to: cursorPos)
        } else {
            phoneNumber.removeLast()
            reformatPhoneNumber()
        }
    }
    
    @IBAction private func callButtonAction(_ sender: DialpadActionButton) {
        phoneNumber = phoneNumberTextField.text ?? ""
        delegate?.dialpadViewControllerDidTapCall?(self, withPhoneNumber: rawPhoneNumber)
    }
    
}

//  MARK: - CustomSizedPresentable

extension DialpadViewController: CustomSizedPresentable {
    
    func customSize(withParentContainerSize containerSize: CGSize) -> CGSize {
        if UIDevice.current.isPhone {
            return CGSize(width: containerSize.width, height: containerSize.height - topSafeAreaInset())
        }
        return Constants.sizeOniPad
    }
    
    func position(withParentContainerSize containerSize: CGSize) -> CGPoint {
        let mySize = customSize(withParentContainerSize: containerSize)
        
        if UIDevice.current.isPhone {
            return CGPoint(x: 0, y: topSafeAreaInset())
        }
        
        return CGPoint(x: (containerSize.width - mySize.width)/2,
                       y: (containerSize.height - mySize.height)/2)
    }
    
}
