//
//  SCETRowItem.h
//  SCEazyTableView
//
//  Created by ty.Chen on 2019/3/6.
//  Copyright © 2019 ty.Chen. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SCETRowItem : NSObject

@property (strong, nonatomic) id rowData;

/**
 Specific reuseIdentifier of cell.
 Attention:the value must be equal to string of cell class.
 */
@property (copy, nonatomic, nonnull) NSString *cellClassString;

@property (assign, nonatomic, readwrite) CGFloat cellHeight;

+ (instancetype)rowItemWithRowData:(id)rowData;

+ (instancetype)rowItemWithRowData:(id)rowData cellClassString:(nonnull NSString *)classString;

- (instancetype)initRowItemWithRowData:(id)rowData;

- (instancetype)initRowItemWithRowData:(id)rowData cellClassString:(nonnull NSString *)classString;

@end
