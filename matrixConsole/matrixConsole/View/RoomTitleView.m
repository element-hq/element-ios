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
    
    // do not start the topic animation asap
    NSTimer * animationTimer;
    
    // restart a killed animation when the application is debackgrounded
    BOOL restartAnimationWhenActive;
}
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *displayNameTextFieldTopConstraint;
@end

@implementation RoomTitleView

- (id) initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appEnteredBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appEnteredForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
    }
    
    return self;
}

- (void)dealloc {
    if (messagesListener && _mxRoom) {
        [_mxRoom removeListener:messagesListener];
        messagesListener = nil;
    }
    _mxRoom = nil;

    // stop any animation
    [self stopTopicAnimation];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
}


- (void)appEnteredBackground {
    restartAnimationWhenActive = [self stopTopicAnimation];
}

- (void)appEnteredForeground {
    if (restartAnimationWhenActive) {
        [self startTopicAnimation];
        restartAnimationWhenActive = NO;
    }
}

- (void)refreshDisplay {
    if (_mxRoom) {
        _displayNameTextField.text = _mxRoom.state.displayname;
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
        [self animateTopic:nil];
    }
}

// start with delay
- (void)startTopicAnimation {
    if (animationTimer) {
        [animationTimer invalidate];
        animationTimer = nil;
    }
    
    // wait a little before really animating the topic text
    animationTimer = [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(animateTopic:) userInfo:self repeats:NO];
}

// animate routine
- (void)animateTopic:(id)sender {
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
    
    // unplug to plug
    _topicTextField.hidden = YES;
    [scrollView addSubview:label];
    [self addSubview:scrollView];
    
    // update the size
    [label sizeToFit];

    // offset
    CGPoint offset = scrollView.contentOffset;
    offset.x = label.frame.size.width - scrollView.frame.size.width;

    // duration (magic computation to give more time if the text is longer)
    CGFloat duration  = label.frame.size.width / scrollView.frame.size.width * 3;

    // animation
    [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionRepeat | UIViewAnimationOptionAutoreverse | UIViewAnimationOptionCurveLinear animations:^{

        [scrollView setContentOffset:offset animated:NO];
        
    } completion:^(BOOL finished) {
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
        
        return YES;
    }
    
    return NO;
}

- (void)dismissKeyboard {
    // Hide the keyboard
    [_displayNameTextField resignFirstResponder];
    [_topicTextField resignFirstResponder];

    // restart the animation
    [self stopTopicAnimation];
    [self startTopicAnimation];
}

- (void)setFrame:(CGRect)frame {
    
    // restart only if there is a frame update
    BOOL restartAnimation = !CGRectEqualToRect(CGRectIntegral(frame), CGRectIntegral(self.frame));
    
    if (restartAnimation) {
        [self stopTopicAnimation];
    }
    
    [super setFrame:frame];
    
    if (restartAnimation) {
        [self startTopicAnimation];
    }
}

@end
