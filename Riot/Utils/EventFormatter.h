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

#import <MatrixKit/MatrixKit.h>

/**
 Link string used in attributed strings to mark a keys re-request action.
 */
FOUNDATION_EXPORT NSString *const kEventFormatterOnReRequestKeysLinkAction;

/**
 Parameters separator in the link string.
 */
FOUNDATION_EXPORT NSString *const kEventFormatterOnReRequestKeysLinkActionSeparator;

/**
 `EventFormatter` class inherits from `MXKEventFormatter` to define Vector formatting
 */
@interface EventFormatter : MXKEventFormatter

/**
 String attributes for event timestamp displayed in chat history.
 */
- (NSDictionary*)stringAttributesForEventTimestamp;

@end
