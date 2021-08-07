//
//  SCETDataManager.h
//  Picasso
//
//  Created by 妈妈网 on 2020/5/15.
//  Copyright © 2020 huangkaizhan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SCETDelegate.h"
#import "SCETDataSource.h"
#import "SCETDataModifier.h"

@interface SCETDataManager : NSObject

@property (nonatomic, strong, readonly) SCETDelegate *delegate;
@property (nonatomic, strong, readonly) SCETDataSource *dataSource;
@property (nonatomic, strong, readonly) SCETDataModifier *dataModifier;
@property (nonatomic, strong, readonly) Class dataSourceClass;
@property (nonatomic, strong, readonly) Class delegateClass;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithSectionItems:(NSArray<SCETSectionItem *> *)sectionItems;
- (instancetype)initWithSectionItems:(NSArray<SCETSectionItem *> *)sectionItems dataSourceClass:(Class)dataSoureClass delegateClass:(Class)delegateClass;

+ (instancetype)dataManagerWithSectionItems:(NSArray<SCETSectionItem *> *)sectionItems;
+ (instancetype)dataManagerWithSectionItems:(NSArray<SCETSectionItem *> *)sectionItems dataSourceClass:(Class)dataSoureClass delegateClass:(Class)delegateClass;


@end
