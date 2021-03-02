// 
// Copyright 2021 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

IB_DESIGNABLE
@interface BadgeLabel : UILabel

@property IBInspectable (nonatomic, weak) UIColor *badgeColor;
@property IBInspectable (nonatomic) CGFloat borderWidth;
@property IBInspectable (nonatomic, weak) UIColor *borderColor;
@property IBInspectable (nonatomic) CGSize padding;

@end

NS_ASSUME_NONNULL_END
