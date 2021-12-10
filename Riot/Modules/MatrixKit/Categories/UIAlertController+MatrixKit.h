/*
 Copyright 2017 Vector Creations Ltd
 
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

#import <UIKit/UIKit.h>

/**
 Define a `UIAlertController` category at MatrixKit level to handle accessibility identifiers.
 */
@interface UIAlertController (MatrixKit)

/**
 Apply an accessibility on the alert view and its items (actions and text fields).
 
 @param accessibilityIdentifier the identifier.
 */
- (void)mxk_setAccessibilityIdentifier:(NSString *)accessibilityIdentifier;

@end
