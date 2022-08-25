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

final class RoomCreationIntroCellContentView: UIView, NibLoadable, Themable {
    // MARK: - Properties
    
    // MARK: Outlets
    
    @IBOutlet var roomAvatarView: RoomAvatarView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var informationLabel: UILabel!
    
    @IBOutlet var addParticipantsContainerView: UIView!
    @IBOutlet var addParticipantsButton: UIButton!
    @IBOutlet var addParticipantsLabel: UILabel!
    
    // MARK: Private
    
    private var theme: Theme!
    private var viewData: RoomCreationIntroViewData?
    
    private var informationTextDefaultAttributes: [NSAttributedString.Key: Any] {
        [.foregroundColor: theme.textSecondaryColor]
    }
    
    private var informationTextBoldAttributes: [NSAttributedString.Key: Any] {
        [.foregroundColor: theme.textSecondaryColor,
         .font: UIFont.boldSystemFont(ofSize: informationLabel.font.pointSize)]
    }
    
    // MARK: Public
    
    var didTapTopic: (() -> Void)?
    var didTapRoomName: (() -> Void)?
    var didTapAddParticipants: (() -> Void)?
    
    // MARK: - Setup
    
    static func instantiate() -> RoomCreationIntroCellContentView {
        let view = RoomCreationIntroCellContentView.loadFromNib()
        view.theme = ThemeService.shared().theme
        return view
    }
    
    // MARK: - Life cycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        setupInformationTextTapGestureRecognizer()
                
        addParticipantsButton.layer.masksToBounds = true
        addParticipantsButton.addTarget(self, action: #selector(socialButtonAction(_:)), for: .touchUpInside)
        
        addParticipantsLabel.text = VectorL10n.roomIntroCellAddParticipantsAction
        
        roomAvatarView.showCameraBadgeOnFallbackImage = true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        addParticipantsButton.layer.cornerRadius = addParticipantsButton.bounds.height / 2.0
        
        // Fix RoomAvatarView layoutSubviews not triggered issue
        roomAvatarView.setNeedsLayout()
    }
    
    // MARK: - Public
    
    func fill(with viewData: RoomCreationIntroViewData) {
        self.viewData = viewData
        titleLabel.text = viewData.roomDisplayName
        informationLabel.attributedText = buildInformationText()
        
        let hideAddParticipants: Bool
        
        switch viewData.dicussionType {
        case .room(_, let canInvitePeople):
            hideAddParticipants = !canInvitePeople
        default:
            hideAddParticipants = true
        }
        
        addParticipantsContainerView.isHidden = hideAddParticipants
        
        roomAvatarView?.fill(with: viewData.avatarViewData)
    }
    
    func update(theme: Theme) {
        self.theme = theme
        
        backgroundColor = theme.backgroundColor
        titleLabel.textColor = theme.textPrimaryColor
        
        informationLabel.attributedText = buildInformationText()
        
        roomAvatarView?.update(theme: theme)
        
        addParticipantsButton.vc_setBackgroundColor(theme.secondaryCircleButtonBackgroundColor, for: .normal)
        
        addParticipantsLabel.textColor = theme.textPrimaryColor
    }
    
    // MARK: - Private
    
    private func buildInformationText() -> NSAttributedString? {
        guard let viewData = viewData else {
            return nil
        }
        
        let informationAttributedText: NSAttributedString
        
        switch viewData.dicussionType {
        case .room(let topic, _):
            informationAttributedText = buildRoomInformationText(with: viewData.roomDisplayName, topic: topic)
        case .directMessage:
            informationAttributedText = buildDMInformationText(with: viewData.roomDisplayName, isDirect: true)
        case .multipleDirectMessage:
            informationAttributedText = buildDMInformationText(with: viewData.roomDisplayName, isDirect: false)
        }
        
        return informationAttributedText
    }
    
    private func buildRoomInformationText(with roomName: String, topic: String?) -> NSAttributedString {
        let attributedString = NSMutableAttributedString()
                                    
        let firstSentencePart1 = NSAttributedString(string: VectorL10n.roomIntroCellInformationRoomSentence1Part1, attributes: informationTextDefaultAttributes)
        let firstSentencePart2 = NSAttributedString(string: roomName, attributes: informationTextBoldAttributes)
        let firstSentencePart3 = NSAttributedString(string: VectorL10n.roomIntroCellInformationRoomSentence1Part3, attributes: informationTextDefaultAttributes)
        
        attributedString.append(firstSentencePart1)
        attributedString.append(firstSentencePart2)
        attributedString.append(firstSentencePart3)
                        
        if let topic = topic, topic.isEmpty == false {
            attributedString.append(NSAttributedString(string: VectorL10n.roomIntroCellInformationRoomWithTopicSentence2(topic), attributes: informationTextDefaultAttributes))
        } else {
            let secondSentencePart1 = NSAttributedString(string: VectorL10n.roomIntroCellInformationRoomWithoutTopicSentence2Part1, attributes: [.foregroundColor: theme.tintColor])
            let secondSentencePart2 = NSAttributedString(string: VectorL10n.roomIntroCellInformationRoomWithoutTopicSentence2Part2, attributes: informationTextDefaultAttributes)
            attributedString.append(secondSentencePart1)
            attributedString.append(secondSentencePart2)
        }
        
        return attributedString
    }
    
    private func buildDMInformationText(with roomName: String, isDirect: Bool) -> NSAttributedString {
        let attributedString = NSMutableAttributedString()
                            
        let firstSentencePart1 = NSAttributedString(string: VectorL10n.roomIntroCellInformationDmSentence1Part1)
        let firstSentencePart2 = NSAttributedString(string: roomName, attributes: informationTextBoldAttributes)
        let firstSentencePart3 = NSAttributedString(string: VectorL10n.roomIntroCellInformationDmSentence1Part3)
        
        attributedString.append(firstSentencePart1)
        attributedString.append(firstSentencePart2)
        attributedString.append(firstSentencePart3)
                        
        if isDirect {
            attributedString.append(NSAttributedString(string: VectorL10n.roomIntroCellInformationDmSentence2, attributes: informationTextDefaultAttributes))
        } else {
            attributedString.append(NSAttributedString(string: VectorL10n.roomIntroCellInformationMultipleDmSentence2, attributes: informationTextDefaultAttributes))
        }
                
        return attributedString
    }
    
    private func setupInformationTextTapGestureRecognizer() {
        var tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleInformationTextTap(_:)))
        informationLabel.isUserInteractionEnabled = true
        informationLabel.addGestureRecognizer(tapGestureRecognizer)
        
        tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleRoomNameTextTap(_:)))
        titleLabel.isUserInteractionEnabled = true
        titleLabel.addGestureRecognizer(tapGestureRecognizer)
    }
    
    @objc private func handleInformationTextTap(_ gestureRecognizer: UITapGestureRecognizer) {
        guard let viewData = viewData else {
            return
        }
        
        if case DiscussionType.room(let topic, _) = viewData.dicussionType {
            // There is no topic defined
            if topic.isEmptyOrNil {
                self.didTapTopic?()
            }
        }
    }
    
    @objc private func handleRoomNameTextTap(_ gestureRecognizer: UITapGestureRecognizer) {
        didTapRoomName?()
    }
    
    @objc private func socialButtonAction(_ sender: UIButton) {
        didTapAddParticipants?()
    }
}
