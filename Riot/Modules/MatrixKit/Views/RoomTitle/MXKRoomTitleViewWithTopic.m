/*
 Copyright 2015 OpenMarket Ltd
 Copyright 2017 Vector Creations Ltd
 Copyright 2018 New Vector Ltd
 
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

#import "MXKRoomTitleViewWithTopic.h"

#import "MXKConstants.h"

#import "NSBundle+MatrixKit.h"
#import "MXRoom+Sync.h"

#import "MXKSwiftHeader.h"

@interface MXKRoomTitleViewWithTopic ()
{
    id roomTopicListener;
    
    // the topic can be animated if it is longer than the screen size
    UIScrollView* scrollView;
    UILabel* label;
    UIView* topicTextFieldMaskView;
    
    // do not start the topic animation asap
    NSTimer * animationTimer;
}
@end

@implementation MXKRoomTitleViewWithTopic

+ (UINib *)nib
{
    return [UINib nibWithNibName:NSStringFromClass([MXKRoomTitleViewWithTopic class])
                          bundle:[NSBundle bundleForClass:[MXKRoomTitleViewWithTopic class]]];
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    // Add an accessory view to the text view in order to retrieve keyboard view.
    self.topicTextField.inputAccessoryView = inputAccessoryView;
    
    self.displayNameTextField.returnKeyType = UIReturnKeyNext;
    self.topicTextField.enabled = NO;
    self.topicTextField.returnKeyType = UIReturnKeyDone;
    self.hiddenTopic = YES;
}

- (void)refreshDisplay
{
    [super refreshDisplay];
    
    if (self.mxRoom)
    {
        // Remove new line characters
        NSString *topic = [MXTools stripNewlineCharacters:self.mxRoom.summary.topic];
        // replace empty string by nil: avoid having the placeholder when there is no topic
        self.topicTextField.text = (topic.length ? topic : nil);
    }
    else
    {
        self.topicTextField.text = nil;
    }
    
    self.hiddenTopic = (!self.topicTextField.text.length);
}

- (void)destroy
{
    // stop any animation
    [self stopTopicAnimation];
    
    [super destroy];
}

- (void)dismissKeyboard
{
    // Hide the keyboard
    [self.topicTextField resignFirstResponder];
    
    // restart the animation
    [self stopTopicAnimation];
    
    [super dismissKeyboard];
}

#pragma mark -

- (void)setMxRoom:(MXRoom *)mxRoom
{
    // Make sure we can access synchronously to self.mxRoom and mxRoom data
    // to avoid race conditions
    MXWeakify(self);
    [mxRoom.mxSession preloadRoomsData:self.mxRoom ? @[self.mxRoom.roomId, mxRoom.roomId] : @[mxRoom.roomId] onComplete:^{
        MXStrongifyAndReturnIfNil(self);

        // Check whether the room is actually changed
        if (self.mxRoom != mxRoom)
        {
            // Remove potential listener
            if (self->roomTopicListener && self.mxRoom)
            {
                MXWeakify(self);
                [self.mxRoom liveTimeline:^(id<MXEventTimeline> liveTimeline) {
                    MXStrongifyAndReturnIfNil(self);

                    [liveTimeline removeListener:self->roomTopicListener];
                    self->roomTopicListener = nil;
                }];
            }

            if (mxRoom)
            {
                // Register a listener to handle messages related to room name
                self->roomTopicListener = [mxRoom listenToEventsOfTypes:@[kMXEventTypeStringRoomTopic] onEvent:^(MXEvent *event, MXTimelineDirection direction, MXRoomState *roomState) {

                    // Consider only live events
                    if (direction == MXTimelineDirectionForwards)
                    {
                        [self refreshDisplay];
                    }
                }];
            }
        }

        super.mxRoom = mxRoom;
    }];
}

- (void)setEditable:(BOOL)editable
{
    self.topicTextField.enabled = editable;
    
    super.editable = editable;
}

- (void)setHiddenTopic:(BOOL)hiddenTopic
{
    [self stopTopicAnimation];
    if (hiddenTopic)
    {
        self.topicTextField.hidden = YES;
        self.displayNameTextFieldTopConstraint.constant = 10;
    }
    else
    {
        self.topicTextField.hidden = NO;
        self.displayNameTextFieldTopConstraint.constant = 0;
    }
}

- (BOOL)isEditing
{
    return (super.isEditing || self.topicTextField.isEditing);
}

#pragma mark -

// start with delay
- (void)startTopicAnimation
{
    // stop any pending timer
    if (animationTimer)
    {
        [animationTimer invalidate];
        animationTimer = nil;
    }
    
    // already animated the topic
    if (scrollView)
    {
        return;
    }
    
    // compute the text width
    UIFont* font = self.topicTextField.font;
    
    // see font description
    if (!font)
    {
        font = [UIFont systemFontOfSize:12];
    }
    
    NSDictionary *attributes = @{NSFontAttributeName: font};
    
    CGSize stringSize = CGSizeMake(CGFLOAT_MAX, self.topicTextField.frame.size.height);
    
    stringSize  = [self.topicTextField.text boundingRectWithSize:stringSize
                                                         options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading
                                                      attributes:attributes
                                                         context:nil].size;
    
    // does not need to animate the text
    if (stringSize.width < self.topicTextField.frame.size.width)
    {
        return;
    }
    
    // put the text in a scrollView to animat it
    scrollView = [[UIScrollView alloc] initWithFrame: self.topicTextField.frame];
    label = [[UILabel alloc] initWithFrame:self.topicTextField.frame];
    label.text = self.topicTextField.text;
    label.textColor = self.topicTextField.textColor;
    label.font = self.topicTextField.font;
    
    // move to the top left
    CGRect topicTextFieldFrame = self.topicTextField.frame;
    topicTextFieldFrame.origin = CGPointZero;
    label.frame = topicTextFieldFrame;
    
    self.topicTextField.hidden = YES;
    [scrollView addSubview:label];
    [self insertSubview:scrollView belowSubview:topicTextFieldMaskView];
    
    // update the size
    [label sizeToFit];
    
    // offset
    CGPoint offset = scrollView.contentOffset;
    offset.x = label.frame.size.width - scrollView.frame.size.width;
    
    // duration (magic computation to give more time if the text is longer)
    CGFloat duration  = label.frame.size.width / scrollView.frame.size.width * 3;
    
    // animate the topic once to display its full content
    [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionAutoreverse | UIViewAnimationOptionCurveLinear animations:^{
        [self->scrollView setContentOffset:offset animated:NO];
    } completion:^(BOOL finished)
    {
        [self stopTopicAnimation];
    }];
}

- (BOOL)stopTopicAnimation
{
    // stop running timers
    if (animationTimer)
    {
        [animationTimer invalidate];
        animationTimer = nil;
    }
    
    // if there is an animation is progress
    if (scrollView)
    {
        self.topicTextField.hidden = NO;
        
        [scrollView.layer removeAllAnimations];
        [scrollView removeFromSuperview];
        scrollView = nil;
        label = nil;
        
        [self addSubview:self.topicTextField];
        
        // must be done to be able to restart the animation
        // the Z order is not kept
        [self bringSubviewToFront:topicTextFieldMaskView];
        
        return YES;
    }
    
    return NO;
}

- (void)editTopic
{
    [self stopTopicAnimation];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.topicTextField becomeFirstResponder];
    });
}

- (void)layoutSubviews
{
    // add a mask to trap the tap events
    // it is faster (and simpliest) than subclassing the scrollview or the textField
    // any other gesture could also be trapped here
    if (!topicTextFieldMaskView)
    {
        topicTextFieldMaskView = [[UIView alloc]  initWithFrame:self.topicTextField.frame];
        topicTextFieldMaskView.backgroundColor = [UIColor clearColor];
        [self addSubview:topicTextFieldMaskView];
        
        // tap -> switch to text edition
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(editTopic)];
        [tap setNumberOfTouchesRequired:1];
        [tap setNumberOfTapsRequired:1];
        [tap setDelegate:self];
        [topicTextFieldMaskView addGestureRecognizer:tap];
        
        // long tap -> animate the topic
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(startTopicAnimation)];
        [topicTextFieldMaskView addGestureRecognizer:longPress];
    }
    
    
    // mother class call
    [super layoutSubviews];
}

- (void)setFrame:(CGRect)frame
{
    // mother class call
    [super setFrame:frame];
    
    // stop any running animation if the frame is updated (screen rotation for example)
    if (!CGRectEqualToRect(CGRectIntegral(frame), CGRectIntegral(self.frame)))
    {
        // stop any running application
        [self stopTopicAnimation];
    }
    
    // update the mask frame
    if (self.topicTextField.hidden)
    {
        topicTextFieldMaskView.frame = CGRectZero;
    }
    else
    {
        topicTextFieldMaskView.frame = self.topicTextField.frame;
    }
    
    // topicTextField switches becomes the first responder or it is not anymore the first responder
    if (self.topicTextField.isFirstResponder != (topicTextFieldMaskView.hidden))
    {
        topicTextFieldMaskView.hidden = self.topicTextField.isFirstResponder;
        
        // move topicTextFieldMaskView to the foreground
        // when topicTextField has been the first responder, it lets a view over topicTextFieldMaskView
        // so restore the expected Z order
        if (!topicTextFieldMaskView.hidden)
        {
            [self bringSubviewToFront:topicTextFieldMaskView];
        }
    }
}

#pragma mark - UITextField delegate

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    // check if the deleaget allows the edition
    if (!self.delegate || [self.delegate roomTitleViewShouldBeginEditing:self])
    {
        NSString *alertMsg = nil;
        
        if (textField == self.displayNameTextField)
        {
            // Check whether the user has enough power to rename the room
            MXRoomPowerLevels *powerLevels = self.mxRoom.dangerousSyncState.powerLevels;
            NSInteger userPowerLevel = [powerLevels powerLevelOfUserWithUserID:self.mxRoom.mxSession.myUser.userId];
            if (userPowerLevel >= [powerLevels minimumPowerLevelForSendingEventAsStateEvent:kMXEventTypeStringRoomName])
            {
                // Only the room name is edited here, update the text field with the room name
                textField.text = self.mxRoom.summary.displayname;
                textField.backgroundColor = [UIColor whiteColor];
            }
            else
            {
                alertMsg = [VectorL10n roomErrorNameEditionNotAuthorized];
            }
            
            // Check whether the user is allowed to change room topic
            if (userPowerLevel >= [powerLevels minimumPowerLevelForSendingEventAsStateEvent:kMXEventTypeStringRoomTopic])
            {
                // Show topic text field even if the current value is nil
                self.hiddenTopic = NO;
                if (alertMsg)
                {
                    // Here the user can only update the room topic, switch on room topic field (without displaying alert)
                    alertMsg = nil;
                    [self.topicTextField becomeFirstResponder];
                    return NO;
                }
            }
        }
        else if (textField == self.topicTextField)
        {
            // Check whether the user has enough power to edit room topic
            MXRoomPowerLevels *powerLevels = self.mxRoom.dangerousSyncState.powerLevels;
            NSInteger userPowerLevel = [powerLevels powerLevelOfUserWithUserID:self.mxRoom.mxSession.myUser.userId];
            if (userPowerLevel >= [powerLevels minimumPowerLevelForSendingEventAsStateEvent:kMXEventTypeStringRoomTopic])
            {
                textField.backgroundColor = [UIColor whiteColor];
                [self stopTopicAnimation];
            }
            else
            {
                alertMsg = [VectorL10n roomErrorTopicEditionNotAuthorized];
            }
        }
        
        if (alertMsg)
        {
            // Alert user
            __weak typeof(self) weakSelf = self;
            if (currentAlert)
            {
                [currentAlert dismissViewControllerAnimated:NO completion:nil];
            }
            currentAlert = [UIAlertController alertControllerWithTitle:nil message:alertMsg preferredStyle:UIAlertControllerStyleAlert];
            
            [currentAlert addAction:[UIAlertAction actionWithTitle:[VectorL10n cancel]
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction * action) {
                                                               
                                                               typeof(self) self = weakSelf;
                                                               self->currentAlert = nil;
                                                               
                                                           }]];
            
            [self.delegate roomTitleView:self presentAlertController:currentAlert];
            return NO;
        }
        return YES;
    }
    else
    {
        return NO;
    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    if (textField == self.topicTextField)
    {
        textField.backgroundColor = [UIColor clearColor];
        
        NSString *topic = textField.text;
        if ((topic.length || self.mxRoom.summary.topic.length) && [topic isEqualToString:self.mxRoom.summary.topic] == NO)
        {
            if ([self.delegate respondsToSelector:@selector(roomTitleView:isSaving:)])
            {
                [self.delegate roomTitleView:self isSaving:YES];
            }
            __weak typeof(self) weakSelf = self;
            [self.mxRoom setTopic:topic success:^{
                
                if (weakSelf)
                {
                    typeof(weakSelf)strongSelf = weakSelf;
                    if ([strongSelf.delegate respondsToSelector:@selector(roomTitleView:isSaving:)])
                    {
                        [strongSelf.delegate roomTitleView:strongSelf isSaving:NO];
                    }
                    
                    // Hide topic field if empty
                    strongSelf.hiddenTopic = !textField.text.length;
                }
                
            } failure:^(NSError *error) {
                
                if (weakSelf)
                {
                    typeof(weakSelf)strongSelf = weakSelf;
                    if ([strongSelf.delegate respondsToSelector:@selector(roomTitleView:isSaving:)])
                    {
                        [strongSelf.delegate roomTitleView:strongSelf isSaving:NO];
                    }
                    
                    // Revert change
                    NSString *topic = [MXTools stripNewlineCharacters:strongSelf.mxRoom.summary.topic];
                    textField.text = (topic.length ? topic : nil);
                    
                    // Hide topic field if empty
                    strongSelf.hiddenTopic = !textField.text.length;
                    
                    MXLogDebug(@"[MXKRoomTitleViewWithTopic] Topic room change failed");
                    // Notify MatrixKit user
                    NSString *myUserId = strongSelf.mxRoom.mxSession.myUser.userId;
                    [[NSNotificationCenter defaultCenter] postNotificationName:kMXKErrorNotification object:error userInfo:myUserId ? @{kMXKErrorUserIdKey: myUserId} : nil];
                }
                
            }];
        }
        else
        {
            // Hide topic field if empty
            self.hiddenTopic = !topic.length;
        }
    }
    else
    {
        // Let super handle displayName text field
        [super textFieldDidEndEditing:textField];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField*) textField
{
    if (textField == self.displayNameTextField)
    {
        // "Next" key has been pressed
        [self.topicTextField becomeFirstResponder];
    }
    else
    {
        // "Done" key has been pressed
        [textField resignFirstResponder];
    }
    return YES;
}


@end
