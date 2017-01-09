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

#import <MatrixKit/MatrixKit.h>

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

@property (nonatomic) IBOutlet MXKImageView *thumbnailView;
@property (nonatomic) IBOutlet UIImageView *thumbnailBadgeView;
@property (nonatomic) IBOutlet UILabel *contactDisplayNameLabel;
@property (nonatomic) IBOutlet UILabel *contactInformationLabel;
@property (nonatomic) IBOutlet UIView *customAccessoryView;

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

