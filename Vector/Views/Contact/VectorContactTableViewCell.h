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

#import <MatrixSDK/MatrixSDK.h>

#import "MXKTableViewCell.h"
#import "MXKCellRendering.h"
#import "MXKImageView.h"

/**
 'ContactTableCell' extends MXKTableViewCell.
 */
@interface VectorContactTableViewCell : MXKTableViewCell <MXKCellRendering>

@property (strong, nonatomic) IBOutlet MXKImageView *thumbnailView;
@property (strong, nonatomic) IBOutlet UILabel *contactDisplayNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *lastPresenceLabel;
@property (weak, nonatomic) IBOutlet UIView *bottomLineSeparator;
@property (weak, nonatomic) IBOutlet UIView *topLineSeparator;
@property (weak, nonatomic) IBOutlet UIView *customAccessoryView;

@property (nonatomic) BOOL showCustomAccessoryView;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *customAccessViewWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *customAccessoryViewLeadingConstraint;

// The room where the contact is.
// It is used to display the member information (like invitation)
// This property is OPTIONAL.
@property  (nonatomic) MXRoom* mxRoom;

// The session where this contact is displayed.
// It is MANDATORY.
@property  (nonatomic) MXSession* mxSession;

@end

