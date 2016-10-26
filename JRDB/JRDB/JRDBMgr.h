//
//  JRDBMgr.h
//  JRDB
//
//  Created by JMacMini on 16/5/10.
//  Copyright © 2016年 Jrwong. All rights reserved.
//

#import "JRPersistent.h"
#import "JRPersistentHandler.h"
#import <Foundation/Foundation.h>

@class JRDBQueue;

@interface JRDBMgr : NSObject

@property (nonatomic, strong, readonly, nonnull)
    NSMutableDictionary<NSString *, id<JRPersistentHandler>> * dbs;///< managered dbs

@property (nonatomic, strong, nullable) id<JRPersistentHandler> defaultDB;///< default db

@property (nonatomic, assign) BOOL debugMode;///< print sql if YES;

+ (instancetype _Nonnull)shareInstance;

#pragma mark - database operation

+ (id<JRPersistentHandler> _Nonnull)defaultDB;
- (id<JRPersistentHandler> _Nullable)databaseWithPath:(NSString * _Nullable)path;
- (void)deleteDatabaseWithPath:(NSString * _Nullable)path;

#pragma mark - logic operation

/**
 在这里注册的类，使用本框架的只能操作已注册的类
 @param clazz 类名
 */
- (void)registerClazz:(Class<JRPersistent> _Nonnull)clazz;
- (void)registerClazzes:(NSArray<Class<JRPersistent>> * _Nonnull)clazzArray;
- (NSArray<Class> * _Nonnull)registeredClazz;


/**
 关闭所有的数据库以及队列, 一般使用在app退出
 */
- (void)close;
- (void)closeDatabaseWithPath:(NSString * _Nonnull)path;
- (void)closeDatabase:(id<JRPersistentHandler> _Nonnull)database;


/**
 清理中间表的缓存垃圾

 @param db
 */
- (void)clearMidTableRubbishDataForDB:(id<JRPersistentHandler> _Nonnull)db;


#pragma mark - Cache DEPRECATED

@property (nonatomic, strong, readonly) NSMutableDictionary<NSString *, JRDBQueue *> * _Nonnull queues NS_DEPRECATED_IOS(1_0, 10_0, "no cached in version 2");

/// 获取每个数据库的同步队列 DEPRECATED @see [JRQueueMgr class]
- (JRDBQueue * _Nullable)queueWithPath:(NSString * _Nonnull)path NS_DEPRECATED_IOS(1_0, 10_0, "see [JRQueueMgr class]");


/// DEPRECATED @see - [id<JRPersistentHandler> jr_update***]
- (void)updateDefaultDB NS_DEPRECATED_IOS(1_0, 10_0, "unusable - [id<JRPersistentHandler> jr_update***]");
/// DEPRECATED @see - [id<JRPersistentHandler> jr_update***]
- (void)updateDB:(id<JRPersistentHandler> _Nonnull)db NS_DEPRECATED_IOS(1_0, 10_0, "unusable - [id<JRPersistentHandler> jr_update***]");



- (void)clearObjCaches NS_DEPRECATED_IOS(1_0, 10_0, "no cached in version 2");

- (NSMutableDictionary<NSString *, id<JRPersistent>> * _Nonnull)recursiveCacheForDBPath:(NSString * _Nonnull)dbpath NS_DEPRECATED_IOS(1_0, 10_0, "no cached in version 2");
- (NSMutableDictionary<NSString *, id<JRPersistent>> * _Nonnull)unRecursiveCacheForDBPath:(NSString * _Nonnull)dbpath NS_DEPRECATED_IOS(1_0, 10_0, "no cached in version 2");

- (id<JRPersistentHandler> _Nullable)createDBWithPath:(NSString * _Nullable)path NS_DEPRECATED_IOS(1_0, 10_0, "use -[databaseWithPath:]");
- (void)deleteDBWithPath:(NSString * _Nullable)path NS_DEPRECATED_IOS(1_0, 10_0, "use -[deleteDatabaseWithPath:]");

@end
