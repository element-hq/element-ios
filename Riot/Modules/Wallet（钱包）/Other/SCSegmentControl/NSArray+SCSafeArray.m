//
//  NSArray+SCSafeArray.m
//  SCSegmentControl
//
//  Created by ty.Chen on 2020/11/24.
//

#import "NSArray+SCSafeArray.h"

@implementation NSArray (SCSafeArray)

- (id)sc_safeObjectAtIndex:(NSInteger)index {
    if (index >= self.count) {
        NSString *tip = [NSString stringWithFormat:@"Array's index out of bounds! index:%zd, count:%zd", index, self.count];
        NSAssert(NO, tip);
        return nil;
    }
    
    return [self objectAtIndex:index];
}

@end
