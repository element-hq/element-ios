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

import GrowingTextView

@objc protocol RoomInputToolbarTextViewDelegate: AnyObject {
    func textView(_ textView: RoomInputToolbarTextView, didReceivePasteForMediaFromSender sender: Any?)
}

class RoomInputToolbarTextView: GrowingTextView {
    
    @objc weak var toolbarDelegate: RoomInputToolbarTextViewDelegate?
    
    override var keyCommands: [UIKeyCommand]? {
        return [UIKeyCommand(input: "\r", modifierFlags: [], action: #selector(keyCommandSelector(_:)))]
    }
    
    @objc private func keyCommandSelector(_ keyCommand: UIKeyCommand) {
        guard keyCommand.input == "\r", let delegate = (self.delegate as? RoomInputToolbarView) else {
            return
        }
        
        delegate.onTouchUp(inside: delegate.rightInputToolbarButton)
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
}
