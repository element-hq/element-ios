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

#import "RoomTitleView.h"

#import "VectorDesignValues.h"

#import "MXRoom+Vector.h"

@implementation RoomTitleView

+ (UINib *)nib
{
    return [UINib nibWithNibName:NSStringFromClass([RoomTitleView class])
                          bundle:[NSBundle bundleForClass:[RoomTitleView class]]];
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.displayNameTextField.textColor = kVectorTextColorBlack;
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(reportTapGesture:)];
    [tap setNumberOfTouchesRequired:1];
    [tap setNumberOfTapsRequired:1];
    [tap setDelegate:self];
    [self.titleMask addGestureRecognizer:tap];
    self.titleMask.userInteractionEnabled = YES;
    
    tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(reportTapGesture:)];
    [tap setNumberOfTouchesRequired:1];
    [tap setNumberOfTapsRequired:1];
    [tap setDelegate:self];
    [self.roomDetailsMask addGestureRecognizer:tap];
    self.roomDetailsMask.userInteractionEnabled = YES;
}

- (void)refreshDisplay
{
    [super refreshDisplay];
    
    if (self.mxRoom)
    {
        self.displayNameTextField.text = self.mxRoom.vectorDisplayname;
    }
}

- (void)reportTapGesture:(UITapGestureRecognizer*)tapGestureRecognizer
{
    if (self.tapGestureDelegate)
    {
        [self.tapGestureDelegate roomTitleView:self recognizeTapGesture:tapGestureRecognizer];
    }
}

@end
