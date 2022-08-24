/*
 Copyright 2015 OpenMarket Ltd
 Copyright 2017 Vector Creations Ltd

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

#import <UIKit/UIKit.h>

#import "MXKConstants.h"

#import "MXKAppSettings.h"

#import "MXAggregatedReactions+MatrixKit.h"
#import "MXEvent+MatrixKit.h"
#import "MXRoom+Sync.h"
#import "NSBundle+MatrixKit.h"
#import "NSBundle+MXKLanguage.h"
#import "UIAlertController+MatrixKit.h"
#import "UIViewController+MatrixKit.h"

#import "MXKEventFormatter.h"

#import "MXKTools.h"

#import "MXKErrorPresentation.h"
#import "MXKErrorPresentable.h"
#import "MXKErrorViewModel.h"
#import "MXKErrorPresentableBuilder.h"
#import "MXKErrorAlertPresentation.h"

#import "MXKViewController.h"
#import "MXKRoomViewController.h"
#import "MXKRecentListViewController.h"
#import "MXKRoomMemberListViewController.h"
#import "MXKSearchViewController.h"
#import "MXKCallViewController.h"
#import "MXKContactListViewController.h"
#import "MXKAccountDetailsViewController.h"
#import "MXKContactDetailsViewController.h"
#import "MXKRoomMemberDetailsViewController.h"
#import "MXKNotificationSettingsViewController.h"
#import "MXKAttachmentsViewController.h"
#import "MXKRoomSettingsViewController.h"
#import "MXKWebViewViewController.h"

#import "MXKAuthenticationViewController.h"
#import "MXKAuthInputsPasswordBasedView.h"
#import "MXKAuthInputsEmailCodeBasedView.h"
#import "MXKAuthenticationFallbackWebView.h"
#import "MXKAuthenticationRecaptchaWebView.h"

#import "MXKView.h"

#import "MXKRoomCreationInputs.h"

#import "MXKInterleavedRecentsDataSource.h"

#import "MXKRoomCreationView.h"

#import "MXKRoomInputToolbarView.h"

#import "MXKRoomDataSourceManager.h"

#import "MXKRoomBubbleCellData.h"
#import "MXKRoomBubbleCellDataWithAppendingMode.h"

#import "MXKAttachment.h"

#import "MXKRecentTableViewCell.h"
#import "MXKInterleavedRecentTableViewCell.h"

#import "MXKPublicRoomTableViewCell.h"

#import "MXKDirectoryServersDataSource.h"
#import "MXKDirectoryServerCellDataStoring.h"
#import "MXKDirectoryServerCellData.h"

#import "MXKRoomMemberTableViewCell.h"
#import "MXKAccountTableViewCell.h"
#import "MXKReadReceiptTableViewCell.h"
#import "MXKPushRuleTableViewCell.h"
#import "MXKPushRuleCreationTableViewCell.h"

#import "MXKTableViewCellWithButton.h"
#import "MXKTableViewCellWithButtons.h"
#import "MXKTableViewCellWithLabelAndButton.h"
#import "MXKTableViewCellWithLabelAndImageView.h"
#import "MXKTableViewCellWithLabelAndMXKImageView.h"
#import "MXKTableViewCellWithLabelAndSlider.h"
#import "MXKTableViewCellWithLabelAndSubLabel.h"
#import "MXKTableViewCellWithLabelAndSwitch.h"
#import "MXKTableViewCellWithLabelAndTextField.h"
#import "MXKTableViewCellWithLabelTextFieldAndButton.h"
#import "MXKTableViewCellWithPicker.h"
#import "MXKTableViewCellWithSearchBar.h"
#import "MXKTableViewCellWithTextFieldAndButton.h"
#import "MXKTableViewCellWithTextView.h"

#import "MXKTableViewHeaderFooterWithLabel.h"

#import "MXKMediaCollectionViewCell.h"
#import "MXKPieChartView.h"
#import "MXKPieChartHUD.h"

#import "MXKRoomTitleView.h"
#import "MXKRoomTitleViewWithTopic.h"

#import "MXKRoomEmptyBubbleTableViewCell.h"

#import "MXKRoomIncomingBubbleTableViewCell.h"
#import "MXKRoomIncomingTextMsgBubbleCell.h"
#import "MXKRoomIncomingTextMsgWithoutSenderInfoBubbleCell.h"
#import "MXKRoomIncomingAttachmentBubbleCell.h"
#import "MXKRoomIncomingAttachmentWithoutSenderInfoBubbleCell.h"

#import "MXKRoomOutgoingBubbleTableViewCell.h"
#import "MXKRoomOutgoingTextMsgBubbleCell.h"
#import "MXKRoomOutgoingTextMsgWithoutSenderInfoBubbleCell.h"
#import "MXKRoomOutgoingAttachmentBubbleCell.h"
#import "MXKRoomOutgoingAttachmentWithoutSenderInfoBubbleCell.h"

#import "MXKSearchCellData.h"
#import "MXKSearchTableViewCell.h"

#import "MXKAccountManager.h"

#import "MXKContactManager.h"

#import "MXK3PID.h"

#import "MXKDeviceView.h"
#import "MXKEncryptionInfoView.h"
#import "MXKEncryptionKeysExportView.h"

#import "MXKCountryPickerViewController.h"
#import "MXKLanguagePickerViewController.h"

#import "MXKSlashCommands.h"
