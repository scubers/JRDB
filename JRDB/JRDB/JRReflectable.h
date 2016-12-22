//
//  JRReflectable.h
//  JRDB
//
//  Created by 王俊仁 on 16/6/5.
//  Copyright © 2016年 Jrwong. All rights reserved.
//

#ifndef JRReflectable_h
#define JRReflectable_h

@class OBJCProperty;

NS_ASSUME_NONNULL_BEGIN

@protocol JRReflectable <NSObject>

@optional
+ (NSString *)fullClazzName;
+ (NSString *)shortClazzName;

/**
 *  返回本类的所有property
 *  @return properties
 */
+ (NSArray<OBJCProperty *> *)objc_properties;

/**
 *  替换本类的方法
 *
 *  @param selector description
 *  @param aSelector description
 *
 *  @return ret
 */
+ (void)objc_exchangeMethod:(SEL)selector withMethod:(SEL)aSelector;


- (NSDictionary<NSString *, id> *)jr_toDict;

@end

NS_ASSUME_NONNULL_END

#endif /* JRReflectable_h */
