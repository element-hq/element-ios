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

#import <Foundation/Foundation.h>

/**
 `MXKResponderRageShaking` defines a protocol an object must conform to handle rage shake
 on view controllers or other kinds of `UIResponder`.
 */
@protocol MXKResponderRageShaking <NSObject>

/**
 Tells the receiver that a motion event has begun.
 
 @param responder the view controller (or another kind of `UIResponder`) which observed the motion.
 */
- (void)startShaking:(UIResponder*)responder;

/**
 Tells the receiver that a motion event has ended.
 
 @param responder the view controller (or another kind of `UIResponder`) which observed the motion.
 */
- (void)stopShaking:(UIResponder*)responder;

/**
 Ignore pending rage shake related to the provided responder.
 
 @param responder a view controller (or another kind of `UIResponder`).
 */
- (void)cancel:(UIResponder*)responder;

@end

