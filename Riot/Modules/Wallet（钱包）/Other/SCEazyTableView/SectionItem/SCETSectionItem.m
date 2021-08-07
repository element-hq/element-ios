//
//  SCETSectionItem.m
//  SCEazyTableView
//
//  Created by ty.Chen on 2019/3/6.
//  Copyright © 2019 ty.Chen. All rights reserved.
//

#import "SCETSectionItem.h"

@implementation SCETSectionItem

#pragma mark - Initialization Functions

+ (instancetype)sc_sectionItemWithRowItems:(NSArray<SCETRowItem *> *)rowItems {
    return [[self alloc] initSectionItemWithRowItems:rowItems];
}

+ (instancetype)sc_sectionItemWithRowItems:(NSArray<SCETRowItem *> *)rowItems sectionCellClassString:(NSString *)classString {
    return [[self alloc] initSectionItemWithRowItems:rowItems sectionCellClassString:classString];
}

- (instancetype)initSectionItemWithRowItems:(NSArray<SCETRowItem *> *)rowItems {
    if (self = [super init]) {
        _rowItems = [rowItems mutableCopy];
    }
    return self;
}

- (instancetype)initSectionItemWithRowItems:(NSArray<SCETRowItem *> *)rowItems sectionCellClassString:(NSString *)classString {
    if (self = [super init]) {
        _rowItems = [rowItems mutableCopy];
        self.sectionCellClassString = classString.copy;
    }
    return self;
}

#pragma mark - Setter

- (void)setSectionCellClassString:(NSString *)sectionCellClassString {
    if ([_sectionCellClassString isEqual:sectionCellClassString] || [_sectionCellClassString isEqualToString:sectionCellClassString]) {
        return;
    }
    _sectionCellClassString = sectionCellClassString;
    
    [self.rowItems enumerateObjectsUsingBlock:^(SCETRowItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.cellClassString = sectionCellClassString;
    }];
}

- (void)setSectionCellHeight:(CGFloat)sectionCellHeight {
    if (_sectionCellHeight == sectionCellHeight) {
        return;
    }
    
    _sectionCellHeight = sectionCellHeight;
    
    [self.rowItems enumerateObjectsUsingBlock:^(SCETRowItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.cellHeight = sectionCellHeight;
    }];
}

@end
