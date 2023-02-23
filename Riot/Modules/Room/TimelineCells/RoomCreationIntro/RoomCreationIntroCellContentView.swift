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
    
    @IBOutlet weak var roomAvatarView: RoomAvatarView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var informationLabel: UILabel!
    
    @IBOutlet weak var addParticipantsContainerView: UIView!
    @IBOutlet weak var addParticipantsButton: UIButton!
    @IBOutlet weak var addParticipantsLabel: UILabel!
    
    // MARK: Private
    
    private var theme: Theme!
    private var viewData: RoomCreationIntroViewData?
    
    private var informationTextDefaultAttributes: [NSAttributedString.Key: Any] {
        return [.foregroundColor: self.theme.textSecondaryColor]
    }
    
    private var informationTextBoldAttributes: [NSAttributedString.Key: Any] {
        return [.foregroundColor: self.theme.textSecondaryColor,
                .font: UIFont.boldSystemFont(ofSize: self.informationLabel.font.pointSize)
        ]
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
        
        self.setupInformationTextTapGestureRecognizer()
                
        self.addParticipantsButton.layer.masksToBounds = true
        self.addParticipantsButton.addTarget(self, action: #selector(socialButtonAction(_:)), for: .touchUpInside)
        
        self.addParticipantsLabel.text = VectorL10n.roomIntroCellAddParticipantsAction
        
        self.roomAvatarView.showCameraBadgeOnFallbackImage = true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.addParticipantsButton.layer.cornerRadius = self.addParticipantsButton.bounds.height/2.0
        
        // Fix RoomAvatarView layoutSubviews not triggered issue
        self.roomAvatarView.setNeedsLayout()
    }
    
    // MARK: - Public
    
    func fill(with viewData: RoomCreationIntroViewData) {
        self.viewData = viewData
        self.titleLabel.text = viewData.roomDisplayName
        self.informationLabel.attributedText = self.buildInformationText()
        
        let hideAddParticipants: Bool
        
        switch viewData.dicussionType {
        case .room(_, let canInvitePeople):
            hideAddParticipants = !canInvitePeople
        default:
            hideAddParticipants = true
        }
        
        self.addParticipantsContainerView.isHidden = hideAddParticipants
        
        self.roomAvatarView?.fill(with: viewData.avatarViewData)
    }
    
    func update(theme: Theme) {
        self.theme = theme
        
        self.backgroundColor = theme.backgroundColor
        self.titleLabel.textColor = theme.textPrimaryColor
        
        self.informationLabel.attributedText = self.buildInformationText()
        
        self.roomAvatarView?.update(theme: theme)
        
        self.addParticipantsButton.vc_setBackgroundColor(theme.secondaryCircleButtonBackgroundColor, for: .normal)
        
        self.addParticipantsLabel.textColor = theme.textPrimaryColor
    }
    
    // MARK: - Private
    
    private func buildInformationText() -> NSAttributedString? {
        guard let viewData = self.viewData else {
            return nil
        }
        
        let informationAttributedText: NSAttributedString
        
        switch viewData.dicussionType {
        case .room(let topic, _):
            informationAttributedText = self.buildRoomInformationText(with: viewData.roomDisplayName, topic: topic)
        case .directMessage:
            informationAttributedText = self.buildDMInformationText(with: viewData.roomDisplayName, isDirect: true)
        case .multipleDirectMessage:
            informationAttributedText = self.buildDMInformationText(with: viewData.roomDisplayName, isDirect: false)
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
            let secondSentencePart1 = NSAttributedString(string: VectorL10n.roomIntroCellInformationRoomWithoutTopicSentence2Part1, attributes: [.foregroundColor: self.theme.tintColor])
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
        self.informationLabel.isUserInteractionEnabled = true
        self.informationLabel.addGestureRecognizer(tapGestureRecognizer)
        
        tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleRoomNameTextTap(_:)))
        self.titleLabel.isUserInteractionEnabled = true
        self.titleLabel.addGestureRecognizer(tapGestureRecognizer)
    }
    
    @objc private func handleInformationTextTap(_ gestureRecognizer: UITapGestureRecognizer) {        
        guard let viewData = self.viewData else {
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
        self.didTapRoomName?()
    }
    
    @objc private func socialButtonAction(_ sender: UIButton) {
        self.didTapAddParticipants?()
    }
}
