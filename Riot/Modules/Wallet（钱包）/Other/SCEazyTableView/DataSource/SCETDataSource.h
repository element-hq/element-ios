//
//  SCETDataSource.h
//  SCEazyTableView
//
//  Created by ty.Chen on 2019/3/6.
//  Copyright © 2019 ty.Chen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SCETSectionItem.h"

#import "SCEazyTableViewCellProtocol.h"

@interface SCETDataSource : NSObject <UITableViewDataSource>

@property (strong, nonatomic) NSMutableArray<SCETSectionItem *> *sectionItems;

+ (instancetype)sc_dataSourceWithSectionItems:(NSArray <SCETSectionItem *> *)sectionItems;

- (instancetype)initDataSourceWithSectionItems:(NSArray <SCETSectionItem *> *)sectionItems;

@end
