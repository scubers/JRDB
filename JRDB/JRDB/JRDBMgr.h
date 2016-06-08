//
//  JRDBMgr.h
//  JRDB
//
//  Created by JMacMini on 16/5/10.
//  Copyright © 2016年 Jrwong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JRPersistent.h"

@class FMDatabase;

@interface JRDBMgr : NSObject

@property (nonatomic, strong) FMDatabase * _Nullable defaultDB;
@property (nonatomic, assign) BOOL debugMode;

+ (instancetype _Nonnull)shareInstance;
+ (FMDatabase * _Nonnull)defaultDB;
- (FMDatabase * _Nullable)createDBWithPath:(NSString * _Nullable)path;
- (void)deleteDBWithPath:(NSString * _Nullable)path;

/**
 *  在这里注册的类，使用本框架的只能操作已注册的类
 *  @param clazz 类名
 */
- (void)registerClazz:(Class<JRPersistent> _Nonnull)clazz;
- (void)registerClazzes:(NSArray<Class<JRPersistent>> * _Nonnull)clazzArray;
- (NSArray<Class> * _Nonnull)registeredClazz;

/**
 * 更新默认数据库的表（或者新建没有的表）
 * 更新的表需要在本类先注册
 */
- (void)updateDefaultDB;
- (void)updateDB:(FMDatabase * _Nonnull)db;


/**
 *  检查是否注册
 *
 *  @param clazz 类
 *  @return 结果
 */
- (BOOL)isValidateClazz:(Class<JRPersistent> _Nonnull)clazz;

/**
 *  清理中间表的缓存辣鸡
 *
 *  @param db
 */
- (void)clearMidTableRubbishDataForDB:(FMDatabase * _Nonnull)db;

@end
