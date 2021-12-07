/*
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

@import Foundation;

#import "MXKErrorPresentable.h"

/**
 `MXKErrorPresentableBuilder` enable to create error to present on screen.
 */
@interface MXKErrorPresentableBuilder : NSObject

/**
 Build a displayable error from a NSError.
 
 @param error an NSError.
 @return Return nil in case of network request cancellation error otherwise return a presentable error from NSError informations.
 */
- (id <MXKErrorPresentable>)errorPresentableFromError:(NSError*)error;

/**
 Build a common displayable error. Generic error message to present as fallback when error explanation can't be user friendly.
 
 @return Common default error.
 */
- (id <MXKErrorPresentable>)commonErrorPresentable;

@end
