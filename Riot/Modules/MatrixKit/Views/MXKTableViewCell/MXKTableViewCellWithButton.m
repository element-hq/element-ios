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

#import "MXKTableViewCellWithButton.h"

@implementation MXKTableViewCellWithButton

- (void)prepareForReuse
{
    [super prepareForReuse];

    // TODO: Code commented for a quick fix for https://github.com/vector-im/riot-ios/issues/1323
    // This line was a fix for https://github.com/vector-im/riot-ios/issues/1354
    // but it creates a regression that is worse than the bug it fixes.
    // self.mxkButton.titleLabel.text = nil;

    [self.mxkButton removeTarget:nil action:nil forControlEvents:UIControlEventAllEvents];
    self.mxkButton.accessibilityIdentifier = nil;
}

@end
