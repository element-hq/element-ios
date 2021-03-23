/*
 Copyright 2015 OpenMarket Ltd
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

#import <Foundation/Foundation.h>
#import <HPGrowingTextView/HPGrowingTextView.h>
#import "RoomInputToolbarView.h"

@interface KeyboardGrowingTextView: HPGrowingTextView
- (NSArray<UIKeyCommand *> *)keyCommands;
@end

@implementation KeyboardGrowingTextView

- (NSArray<UIKeyCommand *> *)keyCommands {
    return @[
             [UIKeyCommand keyCommandWithInput:@"\r" modifierFlags:0 action:@selector(keyCommandSelector:)]
            ];
}

- (void)keyCommandSelector:(UIKeyCommand *)sender {
    if ([sender.input isEqualToString:@"\r"] && [self.delegate isKindOfClass: RoomInputToolbarView.class]){
        RoomInputToolbarView *ritv = (RoomInputToolbarView *)self.delegate;
        [ritv onTouchUpInside:ritv.rightInputToolbarButton]; // touch the Send button.
    }
}

@end
