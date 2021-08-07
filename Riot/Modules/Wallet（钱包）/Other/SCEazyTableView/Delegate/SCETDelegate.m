//
//  SCETDelegate.m
//  SCEazyTableView
//
//  Created by ty.Chen on 2019/3/7.
//  Copyright © 2019 ty.Chen. All rights reserved.
//

#import "SCETDelegate.h"
#import "NSArray+SCSafe.h"


@implementation SCETDelegate

+ (instancetype)sc_tableViewDelegateWithDataSource:(SCETDataSource *)dataSource {
    return [[self alloc] initTableViewDelegateWithDatSource:dataSource];
}

- (instancetype)initTableViewDelegateWithDatSource:(SCETDataSource *)dataSource {
    if (self = [super init]) {
        _dataSource = dataSource;
    }
    return self;
}

#pragma mark - Optional UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    SCETSectionItem *sectionItem = [self.dataSource.sectionItems sc_safeObjectAtIndex:indexPath.section];
    if (!sectionItem) {
        return 44.f;
    }
    
    SCETRowItem *rowItem = [sectionItem.rowItems sc_safeObjectAtIndex:indexPath.row];
    if (!rowItem) {
        return 44.f;
    }
    
    return rowItem.cellHeight;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    SCETSectionItem *sectionItem = [self.dataSource.sectionItems sc_safeObjectAtIndex:indexPath.section];
    if (!sectionItem) {
        return;
    }
    
    SCETRowItem *rowItem = [sectionItem.rowItems sc_safeObjectAtIndex:indexPath.row];
    if (!rowItem) {
        return;
    }
    
    if ([cell conformsToProtocol:@protocol(SCEazyTableViewCellProtocol)] && [cell respondsToSelector:@selector(setupCellWithRowData:)]) {
        [cell performSelector:@selector(setupCellWithRowData:) withObject:rowItem.rowData];
    }
    
    
}

@end
