//
//  YXBaseViewModel.h
//  UniversalApp
//
//  Created by liaoshen on 2021/6/16.
//  Copyright © 2021 voidcat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YXBasicSCETDelegate.h"
NS_ASSUME_NONNULL_BEGIN

@interface YXBaseViewModel : NSObject
@property(nonatomic, strong) SCETDataSource *dataSource;

@property(nonatomic, strong) YXBasicSCETDelegate *delegate;

@property(nonatomic,  strong) SCETDataModifier *dataModidfier;

@property(nonatomic,strong) NSMutableArray *sectionItems;

- (void)resetDataSource:(NSArray<SCETSectionItem *> *)sectionItems;
@end

NS_ASSUME_NONNULL_END
