/*
Copyright 2024 New Vector Ltd.
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MatrixKit.h"

/**
 'ContactTableCell' extends MXKTableViewCell.
 */
@interface ContactTableViewCell : MXKTableViewCell <MXKCellRendering>
{
@protected
    /**
     The current displayed contact.
     */
    MXKContact *contact;
}

@property (weak, nonatomic) IBOutlet MXKImageView *thumbnailView;
@property (weak, nonatomic) IBOutlet UILabel *contactDisplayNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *powerLevelLabel;
@property (weak, nonatomic) IBOutlet UILabel *contactInformationLabel;
@property (weak, nonatomic) IBOutlet UIView *customAccessoryView;
@property (weak, nonatomic) IBOutlet UIImageView *avatarBadgeImageView;

@property (nonatomic) BOOL showCustomAccessoryView;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *customAccessViewWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *customAccessoryViewLeadingConstraint;

/**
 Tell whether the matrix id should be added in the contact display name (NO by default)
 */
@property (nonatomic) BOOL showMatrixIdInDisplayName;

// The room where the contact is.
// It is used to display the member information (like invitation)
// This property is OPTIONAL.
@property  (nonatomic) MXRoom* mxRoom;

@end

