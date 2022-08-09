/*
 Copyright 2014 OpenMarket Ltd
 Copyright 2020 Vector Creations Ltd
 
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
 Section header view class. Respects left and right safe area insets and layouts its subviews.
 */
@interface SectionHeaderView : UITableViewHeaderFooterView

/**
 Default value: 20.0
 */
@property (nonatomic, assign) CGFloat minimumLeftInset;

/**
 Default value: 16.0
 */
@property (nonatomic, assign) CGFloat minimumRightInset;

/**
 Default value: 30.0
 */
@property (nonatomic, assign) CGFloat topViewHeight;

@property (nonatomic, assign) CGFloat topPadding;

/**
 A view which spans the top view. No frame value will be used. Height will be equal to topViewHeight.
 */
@property (nonatomic, strong) UIView *topSpanningView;

/**
 Header label. Only height in frame will be used.
 */
@property (nonatomic, strong) UILabel *headerLabel;

/**
 Accessory view for top view. Both width and height will be used.
 */
@property (nonatomic, strong) UIView *accessoryView;

/**
 Right accessory view for header. Both width and height will be used.
 */
@property (nonatomic, strong) UIView *rightAccessoryView;

/**
 A view which spans the bottom view. No frame value will be used. Height will be remaining of the view at below topViewHeight.
 */
@property (nonatomic, strong) UIView *bottomView;

+ (NSString*)defaultReuseIdentifier;

@end
