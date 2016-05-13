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
 *  类全名
 *
 *  @param clazz 输入类
 *  @return 返回类全名（Swift.UIView）兼顾swift
 */
+ (NSString * _Nonnull)fullClazzName:(Class _Nonnull)clazz;
/**
 *  类简称
 *
 *  @param clazz 输入类
 *  @return 返回类简称 UIView
 */
+ (NSString * _Nonnull)shortClazzName:(Class _Nonnull)clazz;

/**
 *  统一将下划线去掉
 *
 *  @param ivarName _name or name
 *  @return name
 */
+ (NSString * _Nonnull)simpleIvarName:(NSString * _Nonnull)ivarName;

/**
 *  返回类里所有成员变量以及对应的编码
 *
 *  @param clazz 类
 *
 *  @return {ivar:@encode(int),ivar:@encode(int)}
 */
+ (NSDictionary<NSString *, NSString *> * _Nonnull)ivarAndEncode4Clazz:(Class _Nonnull)clazz;



@end
