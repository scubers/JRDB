//
//  JRPersistentUtil.h
//  JRDB
//
//  Created by 王俊仁 on 2016/12/7.
//  Copyright © 2016年 Jrwong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JRPersistent.h"
#import "JRFMDBResultSetHandler.h"

@class JRActivatedProperty;


NS_ASSUME_NONNULL_BEGIN

@interface JRPersistentUtil : NSObject

+ (NSString *)uuid;

/**
 返回所有激活状态的属性，包括其父类

 @param aClass aClass description
 */
+ (NSArray<JRActivatedProperty *> *)allPropertesForClass:(Class<JRPersistent>)aClass;


/**
 根据encode获取数据库类型

 @param encoding encoding description
 */
+ (NSString *)dataBaseTypeWithEncoding:(const char *)encoding;


/**
 根据encode获取数据结果类型

 @param encoding encoding description
 */
+ (RetDataType)retDataTypeWithEncoding:(const char *)encoding;


/**
 根据属性名获取数据库名

 @param propertyName propertyName description
 @param aClass aClass description
 */
+ (NSString *)columnNameWithPropertyName:(NSString *)propertyName inClass:(Class<JRPersistent>)aClass;


/**
 根据属性名获取激活属性

 @param name name description
 @param aClass aClass description
 */
+ (JRActivatedProperty *)activityWithPropertyName:(NSString *)name inClass:(Class<JRPersistent>)aClass;


/**
 获取pk的数据库名

 @param name name description
 @param aClass aClass description
 */
+ (NSString *)getPrimaryKeyByName:(NSString *)name inClass:(Class<JRPersistent>)aClass;

@end

NS_ASSUME_NONNULL_END
