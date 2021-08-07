//
//  NSInvocation+SCWrap.h
//  Pods-SCResponderChainPass_Example
//
//  Created by ty.Chen on 2020/1/7.
//

#import <Foundation/Foundation.h>

@interface NSInvocation (SCWrap)

- (void)sc_wrapAndSetArguments:(NSArray *)arguments needWrap:(BOOL)needWrap;

@end
