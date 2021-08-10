//
//  SCETDataSource.m
//  SCEazyTableView
//
//  Created by ty.Chen on 2019/3/6.
//  Copyright © 2019 ty.Chen. All rights reserved.
//

#import "SCETDataSource.h"
#import "NSArray+SCSafe.h"

static NSString *const kSCETDefaultCellKey = @"kSCETDefaultCellKey";

@implementation SCETDataSource

#pragma mark - Initialization Functions

+ (instancetype)sc_dataSourceWithSectionItems:(NSArray<SCETSectionItem *> *)sectionItems {
    return [[self alloc] initDataSourceWithSectionItems:sectionItems];
}

- (instancetype)initDataSourceWithSectionItems:(NSArray<SCETSectionItem *> *)sectionItems {
    if (self = [super init]) {
        if (!sectionItems) {
            sectionItems = [NSMutableArray array];
        }
        _sectionItems = [sectionItems mutableCopy];
    }
    return self;
}

#pragma mark - Private Functions

- (UITableViewCell *)createDefaultTableViewCellForTableView:(UITableView *)tableView {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kSCETDefaultCellKey];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kSCETDefaultCellKey];
    }
    return cell;
}

#pragma mark - Required UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.sectionItems.count;
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    SCETSectionItem *sectionItem = [self.sectionItems sc_safeObjectAtIndex:section];
    if (!sectionItem) {
        return 0;
    }
    
    return sectionItem.rowItems.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    SCETSectionItem *sectionItem = [self.sectionItems sc_safeObjectAtIndex:indexPath.section];
    if (!sectionItem) {
        return [self createDefaultTableViewCellForTableView:tableView];
    }
    
    SCETRowItem *rowItem = [sectionItem.rowItems sc_safeObjectAtIndex:indexPath.row];
    if (!rowItem) {
        return [self createDefaultTableViewCellForTableView:tableView];
    }
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:rowItem.cellClassString];
    
    if (!cell) {
        cell = [[NSClassFromString(rowItem.cellClassString) alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:rowItem.cellClassString];
    }
    if (!cell) {
        NSAssert(NO, @"cell创建失败为nil，请检查配置");
        // 以防万一rowitem的cellClassString为空或者创建cell为nil，给予默认cell避免闪退
        cell = [self createDefaultTableViewCellForTableView:tableView];
    }
    
    return cell;
    
    
}


@end
