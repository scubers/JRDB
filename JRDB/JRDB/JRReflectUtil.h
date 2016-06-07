//
//  JRReflectUtil.h
//  JRDB
//
//  Created by JMacMini on 16/5/10.
//  Copyright © 2016年 Jrwong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import "JRPersistent.h"

#define isID(name) ([name isEqualToString:@"ID"] || [name isEqualToString:@"_ID"])

@interface JRReflectUtil : NSObject

/**
 *  返回类里所有成员变量以及对应的编码
 *
 *  @param clazz 类
 *
 *  @return {ivar:@encode(int),ivar:@encode(int)} example : {@"_age" : @"i"}
 */
+ (NSDictionary<NSString *, NSString *> * _Nonnull)propNameAndEncode4Clazz:(Class _Nonnull)clazz;


+ (const char * _Nonnull)typeEncoding4InstanceMethod:(SEL _Nonnull)selector inClazz:(Class _Nonnull)clazz;


+ (void)exchangeClazz:(Class _Nonnull)clazz method:(SEL _Nonnull)selector withMethod:(SEL _Nonnull)aSelector;

@end
