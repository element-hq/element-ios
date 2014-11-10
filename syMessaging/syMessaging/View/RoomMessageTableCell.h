/*
 Copyright 2014 OpenMarket Ltd
 
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
#import "CustomTableViewCell.h"

// Room Message Table View Cell
@interface RoomMessageTableCell : CustomTableViewCell
@property (weak, nonatomic) IBOutlet UITextView  *messageTextView;
@property (strong, nonatomic) IBOutlet UIImageView *attachmentView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *msgTextViewWidthConstraint;

@property (strong, nonatomic) NSString *attachedImageURL;
@end

@interface IncomingMessageTableCell : RoomMessageTableCell
@property (weak, nonatomic) IBOutlet UILabel *userNameLabel;
@end

@interface OutgoingMessageTableCell : RoomMessageTableCell
@property (weak, nonatomic) IBOutlet UILabel *unsentLabel;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@end

