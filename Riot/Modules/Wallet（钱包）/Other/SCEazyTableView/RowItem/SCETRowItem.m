//
//  SCETRowItem.m
//  SCEazyTableView
//
//  Created by ty.Chen on 2019/3/6.
//  Copyright © 2019 ty.Chen. All rights reserved.
//

#import "SCETRowItem.h"

@implementation SCETRowItem

+ (instancetype)rowItemWithRowData:(id)rowData {
    return [[self alloc] initRowItemWithRowData:rowData];
}

+ (instancetype)rowItemWithRowData:(id)rowData cellClassString:(nonnull NSString *)classString {
    return [[self alloc] initRowItemWithRowData:rowData cellClassString:classString];
}

- (instancetype)initRowItemWithRowData:(id)rowData {
    if (self = [self init]) {
        _rowData = rowData;
    }
    return self;
}

- (instancetype)initRowItemWithRowData:(id)rowData cellClassString:(nonnull NSString *)classString {
    if (self = [self init]) {
        _rowData = rowData;
        _cellClassString = classString.copy;
    }
    return self;
}

- (instancetype)init {
    if (self = [super init]) {
        _cellHeight = 44.f;
    }
    return self;
}

@end
