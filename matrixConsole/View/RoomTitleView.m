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

#import "RoomTitleView.h"
#import "MatrixHandler.h"

@interface RoomTitleView () {
    id messagesListener;
    
    // the topic can be animated if it is longer than the screen size
    UIScrollView* scrollView;
    UILabel* label;
    UIView* topicTextFieldMaskView;
    
    // do not start the topic animation asap
    NSTimer * animationTimer;
}
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *displayNameTextFieldTopConstraint;
@end

@implementation RoomTitleView

- (void)dealloc {
    if (messagesListener && _mxRoom) {
        [_mxRoom removeListener:messagesListener];
        messagesListener = nil;
    }
    _mxRoom = nil;

    // stop any animation
    [self stopTopicAnimation];
}

- (void)refreshDisplay {
    if (_mxRoom) {
        _displayNameTextField.text = (_mxRoom.state.displayname.length) ? _displayNameTextField.text : @" ";
        _topicTextField.text = _mxRoom.state.topic;
    } else {
        _displayNameTextField.text = nil;
        _topicTextField.text = nil;
    }
    
    self.hiddenTopic = (!_topicTextField.text.length);
}

- (void)setMxRoom:(MXRoom *)mxRoom {
    // Check whether the room is actually changed
    if (_mxRoom != mxRoom) {
        // Remove potential listener
        if (messagesListener && _mxRoom) {
            [_mxRoom removeListener:messagesListener];
            messagesListener = nil;
        }
        
        if (mxRoom) {
            // Register a listener to handle messages related to room name
            messagesListener = [mxRoom listenToEventsOfTypes:@[kMXEventTypeStringRoomName, kMXEventTypeStringRoomTopic, kMXEventTypeStringRoomAliases]
                                                          onEvent:^(MXEvent *event, MXEventDirection direction, MXRoomState *roomState) {
                                                              // Consider only live events
                                                              if (direction == MXEventDirectionForwards) {
                                                                  [self refreshDisplay];
                                                              }
                                                          }];
        }
        _mxRoom = mxRoom;
    }
    // Force refresh
    [self refreshDisplay];
}

- (void)setEditable:(BOOL)editable {
    self.displayNameTextField.enabled = editable;
    self.topicTextField.enabled = editable;
}

- (void)setHiddenTopic:(BOOL)hiddenTopic {
    [self stopTopicAnimation];
    if (hiddenTopic) {
        _topicTextField.hidden = YES;
        _displayNameTextFieldTopConstraint.constant = 10;
    } else {
        _topicTextField.hidden = NO;
        _displayNameTextFieldTopConstraint.constant = 2;
    }
}

// start with delay
- (void)startTopicAnimation {
    // stop any pending timer
    if (animationTimer) {
        [animationTimer invalidate];
        animationTimer = nil;
    }
    
    // already animated the topic
    if (scrollView) {
        return;
    }
    
    // compute the text width
    UIFont* font = _topicTextField.font;
    
    // see font description
    if (!font) {
        font = [UIFont systemFontOfSize:12];
    }
    
    NSDictionary *attributes = @{NSFontAttributeName: font};
    
    CGSize stringSize = CGSizeMake(CGFLOAT_MAX, _topicTextField.frame.size.height);
    
    stringSize  = [_topicTextField.text boundingRectWithSize:stringSize
                                                 options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading
                                              attributes:attributes
                                                 context:nil].size;
    
    // does not need to animate the text
    if (stringSize.width < _topicTextField.frame.size.width) {
        return;
    }
    
    // put the text in a scrollView to animat it
    scrollView = [[UIScrollView alloc] initWithFrame: _topicTextField.frame];
    label = [[UILabel alloc] initWithFrame:_topicTextField.frame];
    label.text = _topicTextField.text;
    label.textColor = _topicTextField.textColor;
    label.font = _topicTextField.font;
    
    // move to the top left
    CGRect topicTextFieldFrame = _topicTextField.frame;
    topicTextFieldFrame.origin = CGPointZero;
    label.frame = topicTextFieldFrame;

    _topicTextField.hidden = YES;
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
        [scrollView setContentOffset:offset animated:NO];
    } completion:^(BOOL finished) {
        [self stopTopicAnimation];
    }];
}

- (BOOL)stopTopicAnimation {
    // stop running timers
    if (animationTimer) {
        [animationTimer invalidate];
        animationTimer = nil;
    }
    
    // if there is an animation is progress
    if (scrollView) {
        _topicTextField.hidden = NO;
        
        [scrollView.layer removeAllAnimations];
        [scrollView removeFromSuperview];
        scrollView = nil;
        label = nil;
    
        [self addSubview:_topicTextField];
        
        // must be done to be able to restart the animation
        // the Z order is not kept
        [self bringSubviewToFront:topicTextFieldMaskView];
        
        return YES;
    }
    
    return NO;
}

- (void)editTopic {
    [self stopTopicAnimation];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [_topicTextField becomeFirstResponder];
    });
}

- (void)dismissKeyboard {
    // Hide the keyboard
    [_displayNameTextField resignFirstResponder];
    [_topicTextField resignFirstResponder];

    // restart the animation
    [self stopTopicAnimation];
}

- (void)layoutSubviews {
    // mother class call
    [super layoutSubviews];

    // add a mask to trap the tap events
    // it is faster (and simpliest) than subclassing the scrollview or the textField
    // any other gesture could also be trapped here
    if (!topicTextFieldMaskView) {
         topicTextFieldMaskView = [[UIView alloc]  initWithFrame:_topicTextField.frame];
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
}

- (void)setFrame:(CGRect)frame {
    // mother class call
    [super setFrame:frame];
    
    // stop any running animation if the frame is updated (screen rotation for example)
    if (!CGRectEqualToRect(CGRectIntegral(frame), CGRectIntegral(self.frame))) {
        // stop any running application
        [self stopTopicAnimation];
    }

    // update the mask frame
    if (self.topicTextField.hidden) {
        topicTextFieldMaskView.frame = CGRectZero;
    } else {
        topicTextFieldMaskView.frame = self.topicTextField.frame;
    }
    
    // topicTextField switches becomes the first responder or it is not anymore the first responder
    if (self.topicTextField.isFirstResponder != (topicTextFieldMaskView.hidden)) {
        topicTextFieldMaskView.hidden = self.topicTextField.isFirstResponder;
        
        // move topicTextFieldMaskView to the foreground
        // when topicTextField has been the first responder, it lets a view over topicTextFieldMaskView
        // so restore the expected Z order
        if (!topicTextFieldMaskView.hidden) {
            [self bringSubviewToFront:topicTextFieldMaskView];
        }
    }
}

@end
