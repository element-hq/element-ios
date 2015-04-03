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
#import "MXCImageView.h"
#import "RoomMessage.h"
#import "PieChartView.h"

// Room Message Table View Cell
@interface RoomMessageTableCell : UITableViewCell
@property (strong, nonatomic) IBOutlet MXCImageView *pictureView;
@property (weak, nonatomic) IBOutlet UITextView  *messageTextView;
@property (strong, nonatomic) IBOutlet MXCImageView *attachmentView;
@property (strong, nonatomic) IBOutlet UIImageView *playIconView;
@property (weak, nonatomic) IBOutlet UIView *dateTimeLabelContainer;

@property (weak, nonatomic) IBOutlet UIView *progressView;
@property (weak, nonatomic) IBOutlet UILabel *statsLabel;
@property (weak, nonatomic) IBOutlet PieChartView *progressChartView;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *msgTextViewTopConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *attachViewWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *attachViewTopConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *dateTimeLabelContainerTopConstraint;

// reference to the linked message
@property (strong, nonatomic) RoomMessage *message;

- (void)startProgressUI;
- (void)stopProgressUI;

- (void)cancelDownload;
@end

@interface IncomingMessageTableCell : RoomMessageTableCell
@property (weak, nonatomic) IBOutlet UIImageView *typingBadge;
@property (weak, nonatomic) IBOutlet UILabel *userNameLabel;
@end

@interface OutgoingMessageTableCell : RoomMessageTableCell

-(void)startUploadAnimating;
-(void)stopAnimating;
@end

