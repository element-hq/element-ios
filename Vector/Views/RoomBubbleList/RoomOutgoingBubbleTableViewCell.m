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

#import "RoomOutgoingBubbleTableViewCell.h"

#pragma mark - UI Constant definitions
#define MXKROOMBUBBLETABLEVIEWCELL_OUTGOING_HEIGHT_REDUCTION_WHEN_SENDER_INFO_IS_HIDDEN -10

@implementation RoomOutgoingBubbleTableViewCell

- (void)dealloc
{
    [self stopAnimating];
}

- (void)render:(MXKCellData *)cellData
{
    [super render:cellData];
    
    if (self.bubbleData)
    {
        // Check whether the previous message has been sent by the same user.
        // The user's picture and name are displayed only for the first message.
        // Handle sender's picture and adjust view's constraints
        if (self.bubbleData.isSameSenderAsPreviousBubble)
        {
            self.pictureView.hidden = YES;
            self.msgTextViewTopConstraint.constant = self.class.cellWithOriginalXib.msgTextViewTopConstraint.constant + MXKROOMBUBBLETABLEVIEWCELL_OUTGOING_HEIGHT_REDUCTION_WHEN_SENDER_INFO_IS_HIDDEN;
            self.attachViewTopConstraint.constant = self.class.cellWithOriginalXib.attachViewTopConstraint.constant + MXKROOMBUBBLETABLEVIEWCELL_OUTGOING_HEIGHT_REDUCTION_WHEN_SENDER_INFO_IS_HIDDEN;
            
            if (!self.dateTimeLabelContainer.hidden)
            {
                self.dateTimeLabelContainerTopConstraint.constant += MXKROOMBUBBLETABLEVIEWCELL_OUTGOING_HEIGHT_REDUCTION_WHEN_SENDER_INFO_IS_HIDDEN;
            }
        }
        
        // Add unsent label for failed components
        for (MXKRoomBubbleComponent *component in self.bubbleData.bubbleComponents)
        {
            if (component.event.mxkState == MXKEventStateSendingFailed)
            {
                UIButton *unsentButton = [[UIButton alloc] initWithFrame:CGRectMake(0, component.position.y, 58 , 20)];
                
                [unsentButton setTitle:[NSBundle mxk_localizedStringForKey:@"unsent"] forState:UIControlStateNormal];
                [unsentButton setTitle:[NSBundle mxk_localizedStringForKey:@"unsent"] forState:UIControlStateSelected];
                [unsentButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
                [unsentButton setTitleColor:[UIColor redColor] forState:UIControlStateSelected];
                
                unsentButton.backgroundColor = [UIColor whiteColor];
                unsentButton.titleLabel.font =  [UIFont systemFontOfSize:14];
                
                [unsentButton addTarget:self action:@selector(onResendToggle:) forControlEvents:UIControlEventTouchUpInside];
                
                [self.dateTimeLabelContainer addSubview:unsentButton];
                self.dateTimeLabelContainer.hidden = NO;
                self.dateTimeLabelContainer.userInteractionEnabled = YES;
                
                // ensure that dateTimeLabelContainer is at front to catch the tap event
                [self.dateTimeLabelContainer.superview bringSubviewToFront:self.dateTimeLabelContainer];
            }
        }
        
        if (self.attachmentView)
        {
            // Check if the image is uploading
            MXKRoomBubbleComponent *component = self.bubbleData.bubbleComponents.firstObject;
            if (MXKEventStateUploading == component.event.mxkState)
            {
                // Retrieve the uploadId embedded in the fake url
                self.bubbleData.uploadId = component.event.content[@"url"];
                
                // And start showing upload progress
                [self startUploadAnimating];
                self.attachmentView.hideActivityIndicator = YES;
            }
            else
            {
                self.attachmentView.hideActivityIndicator = NO;
            }
        }
    }
}

+ (CGFloat)heightForCellData:(MXKCellData *)cellData withMaximumWidth:(CGFloat)maxWidth
{
    CGFloat rowHeight = [super heightForCellData:cellData withMaximumWidth:maxWidth];
    
    MXKRoomBubbleCellData *bubbleData = (MXKRoomBubbleCellData*)cellData;
    
    // Check whether the previous message has been sent by the same user.
    // The user's picture and name are displayed only for the first message.
    if (bubbleData.isSameSenderAsPreviousBubble)
    {
        // Reduce top margin -> row height reduction
        rowHeight += MXKROOMBUBBLETABLEVIEWCELL_OUTGOING_HEIGHT_REDUCTION_WHEN_SENDER_INFO_IS_HIDDEN;
    }
    else
    {
        // We consider a minimun cell height in order to display correctly user's picture
        if (rowHeight < self.cellWithOriginalXib.frame.size.height)
        {
            rowHeight = self.cellWithOriginalXib.frame.size.height;
        }
    }
    
    return rowHeight;
}


- (void)didEndDisplay
{
    [super didEndDisplay];
    
    // Hide potential loading wheel
    [self stopAnimating];
    
    self.dateTimeLabelContainer.userInteractionEnabled = NO;
}

-(void)startUploadAnimating
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kMXKMediaUploadProgressNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUploadProgress:) name:kMXKMediaUploadProgressNotification object:nil];
    
    self.activityIndicator.hidden = NO;
    [self.activityIndicator startAnimating];
    
    MXKMediaLoader *uploader = [MXKMediaManager existingUploaderWithId:self.bubbleData.uploadId];
    if (uploader && uploader.statisticsDict)
    {
        [self.activityIndicator stopAnimating];
        [self updateProgressUI:uploader.statisticsDict];
        
        // Check whether the upload is ended
        if (self.progressChartView.progress == 1.0)
        {
            self.progressView.hidden = YES;
        }
    }
    else
    {
        self.progressView.hidden = YES;
    }
}


-(void)stopAnimating
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kMXKMediaUploadProgressNotification object:nil];
    [self.activityIndicator stopAnimating];
}

- (void)onUploadProgress:(NSNotification *)notif
{
    // sanity check
    if ([notif.object isKindOfClass:[NSString class]])
    {
        NSString *uploadId = notif.object;
        if ([uploadId isEqualToString:self.bubbleData.uploadId])
        {
            [self.activityIndicator stopAnimating];
            [self updateProgressUI:notif.userInfo];
            
            // the upload is ended
            if (self.progressChartView.progress == 1.0)
            {
                self.progressView.hidden = YES;
            }
        }
    }
}

#pragma mark - User actions

- (IBAction)onResendToggle:(id)sender
{
    if ([sender isKindOfClass:[UIButton class]] && self.delegate)
    {
        MXEvent *selectedEvent = nil;
        if (self.bubbleData.bubbleComponents.count == 1)
        {
            MXKRoomBubbleComponent *component = [self.bubbleData.bubbleComponents firstObject];
            selectedEvent = component.event;
        }
        else if (self.bubbleData.bubbleComponents.count)
        {
            // Here the selected view is a textView (attachment has no more than one component)
            
            // Look for the selected component
            UIButton *unsentButton = (UIButton *)sender;
            for (MXKRoomBubbleComponent *component in self.bubbleData.bubbleComponents)
            {
                if (unsentButton.frame.origin.y == component.position.y)
                {
                    selectedEvent = component.event;
                    break;
                }
            }
        }
        
        if (selectedEvent)
        {
            [self.delegate cell:self didRecognizeAction:kMXKRoomBubbleCellUnsentButtonPressed userInfo:@{kMXKRoomBubbleCellEventKey:selectedEvent}];
        }
    }
}

@end