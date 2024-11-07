/*
Copyright 2024 New Vector Ltd.
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
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

