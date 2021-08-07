//
//  NSArray+SCSafe.m
//  SCEazyTableView
//
//  Created by ty.Chen on 2019/3/6.
//  Copyright © 2019 ty.Chen. All rights reserved.
//

#import "NSArray+SCSafe.h"

@implementation NSArray (SCSafe)

- (id)sc_safeObjectAtIndex:(NSUInteger)index {
    if (self.count <= index) {
        return nil;
    }
    
    return [self objectAtIndex:index];
}

@end
