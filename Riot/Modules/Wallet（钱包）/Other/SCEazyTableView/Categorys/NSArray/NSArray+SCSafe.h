//
//  NSArray+SCSafe.h
//  SCEazyTableView
//
//  Created by ty.Chen on 2019/3/6.
//  Copyright © 2019 ty.Chen. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSArray (SCSafe)

- (id)sc_safeObjectAtIndex:(NSUInteger)index;

@end
