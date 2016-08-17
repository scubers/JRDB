//
//  JRDBMgr.h
//  JRDB
//
//  Created by JMacMini on 16/5/10.
//  Copyright © 2016年 Jrwong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JRPersistent.h"
#import "JRDBQueue.h"

@class FMDatabase;

@interface JRDBMgr : NSObject


@property (nonatomic, strong, readonly) NSMutableDictionary<NSString *, JRDBQueue *> * _Nonnull queues;
@property (nonatomic, strong, readonly) NSMutableDictionary<NSString *, FMDatabase *> * _Nonnull dbs;

@property (nonatomic, strong) FMDatabase * _Nullable defaultDB;
@property (nonatomic, assign) BOOL debugMode;

+ (instancetype _Nonnull)shareInstance;

#pragma mark - database operation

+ (FMDatabase * _Nonnull)defaultDB;
- (FMDatabase * _Nullable)databaseWithPath:(NSString * _Nullable)path;
- (void)deleteDatabaseWithPath:(NSString * _Nullable)path;

/**
 *  获取每个数据库的同步队列
 */
- (JRDBQueue * _Nullable)queueWithPath:(NSString * _Nonnull)path;


#pragma mark - logic operation
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
- (BOOL)isValidClazz:(Class<JRPersistent> _Nonnull)clazz;

/**
 *  关闭所有的数据库以及队列, 一般使用在app退出
 */
- (void)close;
- (void)closeDatabaseWithPath:(NSString * _Nonnull)path;
- (void)closeDatabase:(FMDatabase * _Nonnull)database;

#pragma mark - cache

/**
 *  清理中间表的缓存垃圾
 *
 *  @param db
 */
- (void)clearMidTableRubbishDataForDB:(FMDatabase * _Nonnull)db;


/**
 *  清楚缓存
 */
- (void)clearObjCaches;

- (NSMutableDictionary<NSString *, id<JRPersistent>> * _Nonnull)recursiveCacheForDBPath:(NSString * _Nonnull)dbpath;
- (NSMutableDictionary<NSString *, id<JRPersistent>> * _Nonnull)unRecursiveCacheForDBPath:(NSString * _Nonnull)dbpath;

#pragma mark - DEPRECATED

- (FMDatabase * _Nullable)createDBWithPath:(NSString * _Nullable)path NS_DEPRECATED_IOS(1_0, 10_0, "use -[databaseWithPath:]");
- (void)deleteDBWithPath:(NSString * _Nullable)path NS_DEPRECATED_IOS(1_0, 10_0, "use -[deleteDatabaseWithPath:]");

@end
