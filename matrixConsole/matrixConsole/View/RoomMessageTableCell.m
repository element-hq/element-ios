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

- (void)dealloc {
    [self stopAnimating];
}

-(void)startAnimating {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kMediaUploadProgressNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUploadProgress:) name:kMediaUploadProgressNotification object:nil];
    
     self.activityIndicator.hidden = NO;
    [self.activityIndicator startAnimating];
    
    [self updateUploadProgressTo:self.message.uploadProgress];
}

-(void)stopAnimating {
    // remove any pie chart
    [pieChartView removeFromSuperview];
    pieChartView = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kMediaUploadProgressNotification object:nil];
    [self.activityIndicator stopAnimating];
}

- (void)onUploadProgress:(NSNotification *)notif {
    // sanity check
    if ([notif.object isKindOfClass:[NSString class]]) {
        NSString* url = notif.object;
        
        if ([url isEqualToString:self.message.thumbnailURL] || [url isEqualToString:self.message.attachmentURL]) {
            NSNumber* progressNumber = [notif.userInfo valueForKey:kMediaManagerProgressRateKey];
            
            if (progressNumber) {
                [self updateUploadProgressTo:progressNumber.floatValue];
            }
        }
    }
}
- (void) updateUploadProgressTo:(CGFloat)progress {
    // nothing to display
    if (progress <= 0) {
        [pieChartView removeFromSuperview];
        pieChartView = nil;
        
        self.activityIndicator.hidden = NO;
    } else {
        
        if (!pieChartView) {
            pieChartView = [[PieChartView alloc] init];
            pieChartView.frame = self.activityIndicator.frame;
            pieChartView.progress = 0;
            pieChartView.progressColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:0.5];
            pieChartView.unprogressColor = [UIColor clearColor];
            
            [self.contentView addSubview:pieChartView];
        }
        
        self.message.uploadProgress = progress;
        self.activityIndicator.hidden = YES;
        pieChartView.progress = progress;
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    // ensure that the text is still aligned to the left side of the screen
    // even during animation while enlarging/reducing the viewcontroller (with UISplitViewController)
    CGFloat leftInset = self.message.maxTextViewWidth -  self.message.contentSize.width;
    self.messageTextView.contentInset = UIEdgeInsetsMake(0, leftInset, 0, -leftInset);
}
@end