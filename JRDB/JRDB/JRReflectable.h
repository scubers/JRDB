//
//  JRReflectable.h
//  JRDB
//
//  Created by 王俊仁 on 16/6/5.
//  Copyright © 2016年 Jrwong. All rights reserved.
//

#ifndef JRReflectable_h
#define JRReflectable_h

@class OBJCProperty, OBJCMethod;

@protocol JRReflectable <NSObject>

@optional
+ (NSString * _Nonnull)fullClazzName;
+ (NSString * _Nonnull)shortClazzName;

/**
 *  返回本类的所有property
 *  @return properties
 */
+ (NSArray<OBJCProperty *> * _Nonnull)objc_properties;

+ (OBJCProperty * _Nullable)objcPropertyWithName:(NSString * _Nonnull)name;

/**
 *  返回本类的所有methods
 *  @return methods
 */
+ (NSArray<OBJCMethod *> * _Nonnull)objc_methods;

+ (OBJCMethod * _Nullable)objcMethodWithSel:(SEL _Nonnull)selector;

/**
 *  替换本类的方法
 *
 *  @param selector
 *  @param aSelector
 *
 *  @return ret
 */
+ (void)objc_exchangeMethod:(SEL _Nonnull)selector withMethod:(SEL _Nonnull)aSelector;


- (NSDictionary<NSString *, id> * _Nonnull)jr_toDict;

@end

#endif /* JRReflectable_h */
