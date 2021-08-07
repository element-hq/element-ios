//
//  YXBaseViewModel.m
//  UniversalApp
//
//  Created by liaoshen on 2021/6/16.
//  Copyright © 2021 voidcat. All rights reserved.
//

#import "YXBaseViewModel.h"

@implementation YXBaseViewModel
- (NSMutableArray *)sectionItems
{
    if (!_sectionItems) {
        _sectionItems = [NSMutableArray array];
    }
    return _sectionItems;
}

- (void)resetDataSource:(NSArray<SCETSectionItem *> *)sectionItems
{
    self.dataSource = [SCETDataSource sc_dataSourceWithSectionItems:sectionItems];
    self.delegate = [YXBasicSCETDelegate sc_tableViewDelegateWithDataSource:self.dataSource];
    self.dataModidfier = [SCETDataModifier modifierWithDataSource:self.dataSource];
}
@end
