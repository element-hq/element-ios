//
//  SCETDataManager.m
//  Picasso
//
//  Created by 妈妈网 on 2020/5/15.
//  Copyright © 2020 huangkaizhan. All rights reserved.
//

#import "SCETDataManager.h"

@implementation SCETDataManager

- (instancetype)initWithSectionItems:(NSArray<SCETSectionItem *> *)sectionItems {
    return [self initWithSectionItems:sectionItems dataSourceClass:nil delegateClass:nil];
}

- (instancetype)initWithSectionItems:(NSArray<SCETSectionItem *> *)sectionItems dataSourceClass:(Class)dataSoureClass delegateClass:(Class)delegateClass {
    if (self = [super init]) {
        if (!dataSoureClass) {
            dataSoureClass = [SCETDataSource class];
        }
        
        if (!delegateClass) {
            delegateClass = [SCETDelegate class];
        }
        
        BOOL dataSourceClassIsSCETDataSource = [dataSoureClass isSubclassOfClass:[SCETDataSource class]];
        if (!dataSourceClassIsSCETDataSource) {
            NSAssert(dataSourceClassIsSCETDataSource, @"dataSource class isn't subclass of SCETDataSource");
            return nil;
        }
        
         BOOL delegateClassIsSCETDelegate = [delegateClass isSubclassOfClass:[SCETDelegate class]];
        
        if (!delegateClassIsSCETDelegate) {
            NSAssert(delegateClassIsSCETDelegate, @"delegate class isn't subclass of SCETDelegate");
            return nil;
        }
        
        self->_dataSource = [dataSoureClass sc_dataSourceWithSectionItems:sectionItems];
        self->_delegate = [delegateClass sc_tableViewDelegateWithDataSource:self.dataSource];
        self->_dataModifier = [SCETDataModifier modifierWithDataSource:self.dataSource];
        self->_dataSourceClass = dataSoureClass;
        self->_delegateClass = delegateClass;
    }
    return self;
}

+ (instancetype)dataManagerWithSectionItems:(NSArray<SCETSectionItem *> *)sectionItems {
    return [[self alloc] initWithSectionItems:sectionItems];
}

+ (instancetype)dataManagerWithSectionItems:(NSArray<SCETSectionItem *> *)sectionItems dataSourceClass:(Class)dataSoureClass delegateClass:(Class)delegateClass {
    return [[self alloc] initWithSectionItems:sectionItems dataSourceClass:dataSoureClass delegateClass:delegateClass];
}

@end
