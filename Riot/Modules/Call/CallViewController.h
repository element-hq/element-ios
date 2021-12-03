/*
 Copyright 2016 OpenMarket Ltd
 
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

#import "MatrixKit.h"

/**
 'CallViewController' instance displays a call. Only one matrix session is supported by this view controller.
 */
@interface CallViewController : MXKCallViewController

@property (weak, nonatomic) IBOutlet UIButton *chatButton;

@property (weak, nonatomic) IBOutlet UIView *callControlsBackgroundView;

@property (unsafe_unretained, nonatomic) IBOutlet NSLayoutConstraint *callerImageViewWidthConstraint;

//  Effect views
@property (weak, nonatomic) IBOutlet MXKImageView *blurredCallerImageView;

// At the end of call, this flag indicates if the prompt to use the fallback should be displayed
@property (nonatomic) BOOL shouldPromptForStunServerFallback;

@end
