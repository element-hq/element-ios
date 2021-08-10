//
//  SCEventProxyProtocol.h
//  Test
//
//  Created by ty.Chen on 2019/12/27.
//  Copyright © 2019 ty.Chen. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol SCEventProxyProtocol <NSObject>

@optional

/// 处理事件的代理方法（默认拆包：将NSValue转化为对应的基本数据类型和结构体）
/// @param eventName 处理的事件名称
/// @param paramaters 传入的参数
- (void)handleEventProxyForEvent:(NSString *)eventName paramaters:(NSArray *)paramaters;

/// 处理事件的代理方法
/// @param eventName 处理事件的代理方法
/// @param paramaters 处理的事件名称
/// @param needWrap 是否需要拆包
- (void)handleEventProxyForEvent:(NSString *)eventName paramaters:(NSArray *)paramaters needWrap:(BOOL)needWrap;

@end
