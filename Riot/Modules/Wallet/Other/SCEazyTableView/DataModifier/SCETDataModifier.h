//
//  SCETDataModifier.h
//  Picasso
//
//  Created by 妈妈网 on 2020/5/15.
//  Copyright © 2020 huangkaizhan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SCETDataSource.h"

@interface SCETDataModifier : NSObject

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithDataSource:(SCETDataSource *)dataSource;
+ (instancetype)modifierWithDataSource:(SCETDataSource *)dataSource;

- (void)addSectionItem:(SCETSectionItem *)sectionItem;
- (void)addRowItem:(SCETRowItem *)rowItem section:(NSInteger)section;

- (void)insertSectionItem:(SCETSectionItem *)sectionItem atIndex:(NSInteger)index;
- (void)insertRowItem:(SCETRowItem *)rowItem indexPath:(NSIndexPath *)indexPath;

- (void)removeSectionItem:(SCETSectionItem *)sectionItem;
- (void)removeRowItem:(SCETRowItem *)rowItem;
- (void)removeSectionAtIndex:(NSInteger)index;
- (void)removeRowItemAtIndexPath:(NSIndexPath *)indexPath;

- (void)updateDataSource:(SCETDataSource *)dataSource;

- (void)updateSectionItem:(SCETSectionItem *)sectionItem section:(NSInteger)section;

- (void)updateRowItem:(SCETRowItem *)rowItem indexPath:(NSIndexPath *)indexPath;

- (NSInteger)retrieveIndexForSectionItem:(SCETSectionItem *)sectionItem;
- (NSIndexPath *)retrieveIndexPathForRowItem:(SCETRowItem *)rowItem;

@end
