//
//  SCETDataModifier.m
//  Picasso
//
//  Created by 妈妈网 on 2020/5/15.
//  Copyright © 2020 huangkaizhan. All rights reserved.
//

#import "SCETDataModifier.h"
#import "NSArray+SCSafe.h"

@interface SCETDataModifier ()

@property (nonatomic, strong) SCETDataSource *dataSource;

@end

@implementation SCETDataModifier

- (instancetype)initWithDataSource:(SCETDataSource *)dataSource {
    if (self = [super init]) {
        self.dataSource = dataSource;
    }
    return self;
}

+ (instancetype)modifierWithDataSource:(SCETDataSource *)dataSource {
    return [[self alloc] initWithDataSource:dataSource];
}

- (void)addSectionItem:(SCETSectionItem *)sectionItem {
    if (!sectionItem) {
        NSAssert(sectionItem, @"sectionItem is nil");
        return;
    }
    
    [self.dataSource.sectionItems addObject:sectionItem];
}

- (void)addRowItem:(SCETRowItem *)rowItem section:(NSInteger)section {
    if (!rowItem) {
        NSAssert(rowItem, @"rowItem is nil");
        return;
    }
    BOOL outOfBounds = section >= self.dataSource.sectionItems.count;
    if (outOfBounds) {
        NSAssert(!outOfBounds, @"Section out of bounds");
        return;
    }
    
    SCETSectionItem *sectionItem = [self.dataSource.sectionItems sc_safeObjectAtIndex:section];
    NSMutableArray *rowItems = [NSMutableArray arrayWithArray:sectionItem.rowItems];
    [rowItems addObject:rowItem];
}

- (void)insertSectionItem:(SCETSectionItem *)sectionItem atIndex:(NSInteger)index {
    if (!sectionItem) {
        NSAssert(sectionItem, @"sectionItem is nil");
        return;
    }
    BOOL outOfBounds = index >= self.dataSource.sectionItems.count;
    if (outOfBounds) {
        [self addSectionItem:sectionItem];
        return;
    }
    
    [self.dataSource.sectionItems insertObject:sectionItem atIndex:index];
}

- (void)insertRowItem:(SCETRowItem *)rowItem indexPath:(NSIndexPath *)indexPath {
    if (!rowItem) {
        NSAssert(rowItem, @"rowItem is nil");
        return;
    }
    BOOL sectionOutOfBounds = indexPath.section >= self.dataSource.sectionItems.count;
    if (sectionOutOfBounds) {
        return;
    }
    
    SCETSectionItem *sectionItem = [self.dataSource.sectionItems sc_safeObjectAtIndex:indexPath.section];
    BOOL rowOutOfBounds = indexPath.row >= sectionItem.rowItems.count;
    if (rowOutOfBounds) {
        [self addRowItem:rowItem section:indexPath.section];
        return;
    }
    
    [sectionItem.rowItems insertObject:rowItem atIndex:indexPath.row];
}

- (void)removeSectionItem:(SCETSectionItem *)sectionItem {
    if (![self.dataSource.sectionItems containsObject:sectionItem]) {
        return;
    }
    
    [self.dataSource.sectionItems removeObject:sectionItem];
}

- (void)removeRowItem:(SCETRowItem *)rowItem {
    [self.dataSource.sectionItems enumerateObjectsUsingBlock:^(SCETSectionItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        for (SCETRowItem *subRowItem in obj.rowItems.reverseObjectEnumerator) {
            if ([subRowItem isEqual:rowItem]) {
                [obj.rowItems removeObject:subRowItem];
            }
        }
    }];
}

- (void)removeSectionAtIndex:(NSInteger)index {
    BOOL outOfBounds = index >= self.dataSource.sectionItems.count;
    if (outOfBounds) {
        NSAssert(!outOfBounds, @"index out of bounds");
        return;
    }
    
    [self.dataSource.sectionItems removeObjectAtIndex:index];
}

- (void)removeRowItemAtIndexPath:(NSIndexPath *)indexPath {
    BOOL sectionOutOfBounds = indexPath.section >= self.dataSource.sectionItems.count;
    if (sectionOutOfBounds) {
        NSAssert(!sectionOutOfBounds, @"section out of bounds");
        return;
    }
    
    SCETSectionItem *sectionItem = [self.dataSource.sectionItems sc_safeObjectAtIndex:indexPath.section];
    BOOL rowOutOfBounds = indexPath.row >= sectionItem.rowItems.count;
    if (rowOutOfBounds) {
        NSAssert(!rowOutOfBounds, @"row out of bounds");
        return;
    }
    
    [sectionItem.rowItems removeObjectAtIndex:indexPath.row];
}

- (void)updateDataSource:(SCETDataSource *)dataSource {
    self->_dataSource = dataSource;
}

- (void)updateRowItem:(SCETRowItem *)rowItem indexPath:(NSIndexPath *)indexPath {
    if (!rowItem) {
        NSAssert(rowItem, @"rowItem is nil");
        return;
    }
    
    BOOL outOfBounds = indexPath.section >= self.dataSource.sectionItems.count;
    if (outOfBounds) {
        NSAssert(!outOfBounds, @"section out of bounds");
        return;
    }
    
    SCETSectionItem *sectionItem = [self.dataSource.sectionItems sc_safeObjectAtIndex:indexPath.section];
    
    sectionItem.rowItems[indexPath.row] = rowItem;
}

- (void)updateSectionItem:(SCETSectionItem *)sectionItem section:(NSInteger)section {
    BOOL outOfBounds = section >= self.dataSource.sectionItems.count;
    if (outOfBounds) {
        NSAssert(!outOfBounds, @"section out of bounds");
        return;
    }
    
    [self.dataSource.sectionItems replaceObjectAtIndex:section withObject:sectionItem];
}

- (NSInteger)retrieveIndexForSectionItem:(SCETSectionItem *)sectionItem {
    return [self.dataSource.sectionItems indexOfObject:sectionItem];
}

- (NSIndexPath *)retrieveIndexPathForRowItem:(SCETRowItem *)rowItem {
    if (!rowItem) {
        return nil;
    }
    
    __block NSIndexPath *indexPath = nil;
    [self.dataSource.sectionItems enumerateObjectsUsingBlock:^(SCETSectionItem *sectionItem, NSUInteger sectionItemIndex, BOOL *stop) {
        [sectionItem.rowItems enumerateObjectsUsingBlock:^(SCETRowItem *subRowItem, NSUInteger rowItemIndex, BOOL *stop) {
            if ([subRowItem isEqual:rowItem]) {
                indexPath = [NSIndexPath indexPathForRow:rowItemIndex inSection:sectionItemIndex];
            }
        }];
    }];
    
    return indexPath;
}


@end
