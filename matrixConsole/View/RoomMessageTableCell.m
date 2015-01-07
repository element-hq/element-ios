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

#import "RoomMessageTableCell.h"
#import "MediaManager.h"
#import "PieChartView.h"


@implementation RoomMessageTableCell
@end


@implementation IncomingMessageTableCell
@end

@interface OutgoingMessageTableCell () {
    PieChartView* pieChartView;
}

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@end

@implementation OutgoingMessageTableCell

-(void)startAnimating {
    [self.activityIndicator startAnimating];
}

-(void)stopAnimating {
    [self.activityIndicator stopAnimating];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    // ensure that the text is still aligned to the left side of the screen
    // even during animation while enlarging/reducing the viewcontroller (with UISplitViewController)
    CGFloat leftInset = self.message.maxTextViewWidth -  self.message.contentSize.width;
    self.messageTextView.contentInset = UIEdgeInsetsMake(0, leftInset, 0, -leftInset);
}
@end