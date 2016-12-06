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

#define isID(name) ([name.uppercaseString isEqualToString:@"ID"] || [name.uppercaseString isEqualToString:@"_ID"])

@class JRActivatedProperty;

NS_ASSUME_NONNULL_BEGIN

@interface JRReflectUtil : NSObject

/**
 *  返回类里所有成员变量以及对应的编码
 *
 *  @param clazz 类
 *
 *  @return {ivar:@encode(int),ivar:@encode(int)} example : {@"_age" : @"i"}
 */
+ (NSDictionary<NSString *, NSString *> *)propNameAndEncode4Clazz:(Class<JRPersistent>)clazz;

+ (NSArray<JRActivatedProperty *> *)activitedProperties4Clazz:(Class<JRPersistent>)clazz;

@end

NS_ASSUME_NONNULL_END
