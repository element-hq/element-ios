//
//  SCETSectionItem.h
//  SCEazyTableView
//
//  Created by ty.Chen on 2019/3/6.
//  Copyright © 2019 ty.Chen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SCETRowItem.h"

@interface SCETSectionItem : NSObject

@property (strong, nonatomic) NSMutableArray<SCETRowItem *> *rowItems;

/**
 Specify reuseIdentifier of cells at section.
 */
@property (copy, nonatomic) NSString *sectionCellClassString;

@property (assign, nonatomic) CGFloat sectionCellHeight;

+ (instancetype)sc_sectionItemWithRowItems:(NSArray <SCETRowItem *> *)rowItems;

+ (instancetype)sc_sectionItemWithRowItems:(NSArray<SCETRowItem *> *)rowItems sectionCellClassString:(NSString *)classString;

- (instancetype)initSectionItemWithRowItems:(NSArray <SCETRowItem *> *)rowItems;

- (instancetype)initSectionItemWithRowItems:(NSArray<SCETRowItem *> *)rowItems sectionCellClassString:(NSString *)classString;

@end
