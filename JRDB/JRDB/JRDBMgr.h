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

NS_ASSUME_NONNULL_BEGIN

@interface JRDBMgr : NSObject

@property (nonatomic, strong, readonly) NSMutableDictionary<NSString *, id<JRPersistentHandler>> * dbs;///< managered dbs

@property (nonatomic, strong, nullable) id<JRPersistentHandler> defaultDB;///< default db

@property (nonatomic, assign) BOOL debugMode;///< print sql if YES;

+ (instancetype)shareInstance;

#pragma mark - database operation

+ (id<JRPersistentHandler>)defaultDB;
- (id<JRPersistentHandler> _Nullable)databaseWithPath:(NSString * _Nullable)path;
- (void)deleteDatabaseWithPath:(NSString * _Nullable)path;

#pragma mark - logic operation

/**
 在这里注册的类，使用本框架的只能操作已注册的类
 @param clazz 类名
 */
- (void)registerClazz:(Class<JRPersistent>)clazz;
- (void)registerClazzes:(NSArray<Class<JRPersistent>> *)clazzArray;
- (NSArray<Class> *)registeredClazz;


/**
 关闭所有的数据库以及队列, 一般使用在app退出
 */
- (void)close;
- (void)closeDatabaseWithPath:(NSString *)path;
- (void)closeDatabase:(id<JRPersistentHandler>)database;


/**
 清理中间表的缓存垃圾

 @param db
 */
- (void)clearMidTableRubbishDataForDB:(id<JRPersistentHandler>)db;


@end


NS_ASSUME_NONNULL_END
