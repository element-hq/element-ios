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
@import UIKit;

#import "MXKErrorPresentable.h"

/**
 `MXKErrorPresentation` describe an error display handler for presenting error from a view controller.
 */
@protocol MXKErrorPresentation

- (void)presentErrorFromViewController:(UIViewController*)viewController
                                 title:(NSString*)title
                               message:(NSString*)message
                              animated:(BOOL)animated
                               handler:(void (^)(void))handler;

- (void)presentErrorFromViewController:(UIViewController*)viewController
                              forError:(NSError*)error
                              animated:(BOOL)animated
                               handler:(void (^)(void))handler;

- (void)presentGenericErrorFromViewController:(UIViewController*)viewController
                                     animated:(BOOL)animated
                                      handler:(void (^)(void))handler;

@required

- (void)presentErrorFromViewController:(UIViewController*)viewController
                   forErrorPresentable:(id<MXKErrorPresentable>)errorPresentable
                              animated:(BOOL)animated
                               handler:(void (^)(void))handler;

@end
