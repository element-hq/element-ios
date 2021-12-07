/*
 Copyright 2015 OpenMarket Ltd
 
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

#import "MXKTableViewCell.h"

#import "MXKCellRendering.h"
#import "MXKImageView.h"

/**
 List the accessory view types for a 'MXKContactTableCell' instance.
 */
typedef enum : NSUInteger {
    /**
     Don't show accessory view by default.
     */
    MXKContactTableCellAccessoryCustom,
    /**
     The accessory view is automatically handled. It shown only for contact with matrix identifier(s).
     */
    MXKContactTableCellAccessoryMatrixIcon
    
} MXKContactTableCellAccessoryType;


#pragma mark - MXKCellRenderingDelegate cell tap locations

/**
 Action identifier used when the user tapped on contact thumbnail view.
 
 The `userInfo` dictionary contains an `NSString` object under the `kMXKContactCellContactIdKey` key, representing the contact id of the tapped avatar.
 */
extern NSString *const kMXKContactCellTapOnThumbnailView;

/**
 Notifications `userInfo` keys
 */
extern NSString *const kMXKContactCellContactIdKey;

/**
 'MXKContactTableCell' is a base class for displaying a contact.
 */
@interface MXKContactTableCell : MXKTableViewCell <MXKCellRendering>

@property (strong, nonatomic) IBOutlet MXKImageView *thumbnailView;

@property (strong, nonatomic) IBOutlet UILabel *contactDisplayNameLabel;
@property (strong, nonatomic) IBOutlet UILabel *matrixDisplayNameLabel;
@property (strong, nonatomic) IBOutlet UILabel *matrixIDLabel;

@property (strong, nonatomic) IBOutlet UIView *contactAccessoryView;
@property (unsafe_unretained, nonatomic) IBOutlet NSLayoutConstraint *contactAccessoryViewHeightConstraint;
@property (unsafe_unretained, nonatomic) IBOutlet NSLayoutConstraint *contactAccessoryViewWidthConstraint;
@property (strong, nonatomic) IBOutlet UIImageView *contactAccessoryImageView;
@property (strong, nonatomic) IBOutlet UIButton *contactAccessoryButton;

/**
 The default picture displayed when no picture is available.
 */
@property (nonatomic) UIImage *picturePlaceholder;

/**
 The thumbnail display box type ('MXKTableViewCellDisplayBoxTypeDefault' by default)
 */
@property (nonatomic) MXKTableViewCellDisplayBoxType thumbnailDisplayBoxType;

/**
 The accessory view type ('MXKContactTableCellAccessoryCustom' by default)
 */
@property (nonatomic) MXKContactTableCellAccessoryType contactAccessoryViewType;

/**
 Tell whether the matrix presence of the contact is displayed or not (NO by default)
 */
@property (nonatomic) BOOL hideMatrixPresence;

@end

