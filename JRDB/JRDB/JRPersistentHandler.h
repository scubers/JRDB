//
//  JRPersistentHandler.h
//  JRDB
//
//  Created by J on 2016/10/25.
//  Copyright © 2016年 Jrwong. All rights reserved.
//

#ifndef JRPersistentHandler_h
#define JRPersistentHandler_h

#import "JRPersistent.h"

@class JRSql;

@protocol
JRPersistentBaseHandler,
JRPersistentOperationsHandler,
JRPersistentRecursiveOperationsHandler;

NS_ASSUME_NONNULL_BEGIN

/************************************************************************/
#pragma mark - base

@protocol JRPersistentBaseHandler <NSObject>

@optional

- (id<JRPersistentOperationsHandler>)jr_getOperationHandler;
- (id<JRPersistentRecursiveOperationsHandler>)jr_getRecursiveOperationHandler;


@required

@property (nonatomic, strong) NSOperationQueue *jr_operationQueue;
@property (nonatomic, assign, readonly) BOOL jr_isTransactioning;

- (NSString *)jr_handlerIdentifier;

- (BOOL)jr_openSynchronized:(BOOL)synchronized;

- (BOOL)jr_closeSynchronized:(BOOL)synchronized;

- (BOOL)jr_startTransaction;
- (BOOL)jr_commitTransction;
- (BOOL)jr_rollbackTransction;


- (BOOL)jr_tableExists:(NSString *)tableName;

- (BOOL)jr_columnExists:(NSString *)column inTable:(NSString *)tableName;

/**
 使用block来进行队列操作，后台操作，线程安全

 @param block 执行block
 */
- (void)jr_inQueue:(void (^)(id<JRPersistentBaseHandler> handler))block;

/**
 事物回滚操作

 @param block 执行block
 */
- (BOOL)jr_inTransaction:(void (^)(id<JRPersistentBaseHandler> handler, BOOL * rollBack))block;


/**
 您不会用到此方法, 擅自使用会造成数据库lock @see jr_inTransaction
 当前线程执行某个block, block 执行是必须有事务，useTransaction可以使用默认事务

 @param block description
 @param useTransaction 是否使用默认事务 NO:需要自己开启和提交事务
 */
- (BOOL)jr_executeUseTransaction:(BOOL)useTransaction block:(BOOL (^)(id<JRPersistentBaseHandler> handler))block;

/**
 任务是否同步执行

 @param sync  是否同步执行
 @param block description

 */
- (id _Nullable)jr_executeSync:(BOOL)sync block:(id _Nullable (^)(id<JRPersistentBaseHandler> handler))block;

/**
 执行sql 更新

 @param sql description
 */
- (BOOL)jr_executeUpdate:(JRSql *)sql;
- (BOOL)jr_executeUpdate:(NSString *)sql params:(NSArray * _Nullable)params;

/**
 执行sql 查询

 @param sql description
 */
- (id)jr_executeQuery:(JRSql *)sql;
- (id)jr_executeQuery:(NSString *)sql params:(NSArray * _Nullable)params;

@end


/*******************************************************/

#pragma mark - operations

@protocol JRPersistentOperationsHandler <NSObject>

@required

#pragma mark table operations

/**
 *  建表操作
 *
 *  @param clazz 对应表的类
 */
- (BOOL)jr_createTable4Clazz:(Class<JRPersistent>)clazz synchronized:(BOOL)synchronized;


/**
 *  把表删了，重新创建
 *
 *  @param clazz 类
 *
 *  @return 是否成功
 */
- (BOOL)jr_truncateTable4Clazz:(Class<JRPersistent>)clazz synchronized:(BOOL)synchronized;


/**
 *  更新表操作
 *  (只会添加字段，不会删除和更改字段类型)
 *  @param clazz 对应表的类
 */
- (BOOL)jr_updateTable4Clazz:(Class<JRPersistent>)clazz synchronized:(BOOL)synchronized;

/**
 *  删除表
 *
 *  @param clazz 对应表的类
 */
- (BOOL)jr_dropTable4Clazz:(Class<JRPersistent>)clazz synchronized:(BOOL)synchronized;

/**
 *  检查对应类的表是否存在
 *
 *  @param clazz 类
 *
 *  @return 是否存在
 */
- (BOOL)jr_checkExistsTable4Clazz:(Class<JRPersistent>)clazz synchronized:(BOOL)synchronized;

#pragma mark  save

/**
 *  只保存one
 *
 *  @param one description
 */
- (BOOL)jr_saveOne:(id<JRPersistent>)one useTransaction:(BOOL)useTransaction synchronized:(BOOL)synchronized;

/**
 *  保存数组
 *
 *  @param objects description
 *  @param useTransaction 若外层有事务，请用NO，若没有，请用YES
 */
- (BOOL)jr_saveObjects:(NSArray<id<JRPersistent>> *)objects useTransaction:(BOOL)useTransaction synchronized:(BOOL)synchronized;

#pragma mark  update


/**
 *  更新one
 *
 *  @param one description
 *  @param columns 需要更新的字段
 */
- (BOOL)jr_updateOne:(id<JRPersistent>)one columns:(NSArray<NSString *> * _Nullable)columns useTransaction:(BOOL)useTransaction synchronized:(BOOL)synchronized;


/**
 *  更新array
 *
 *  @param objects description
 *  @param columns 需要更新的字段
 *  @param useTransaction 若外层有事务，请用NO，若没有，请用YES
 */
- (BOOL)jr_updateObjects:(NSArray<id<JRPersistent>> *)objects columns:(NSArray<NSString *> * _Nullable)columns useTransaction:(BOOL)useTransaction synchronized:(BOOL)synchronized;

#pragma mark  delete


/**
 *  删除one，可选择自带事务或者自行在外层包裹事务
 *
 *  @param one description
 *  @param useTransaction 若外层有事务，请用NO，若没有，请用YES
 */
- (BOOL)jr_deleteOne:(id<JRPersistent>)one useTransaction:(BOOL)useTransaction synchronized:(BOOL)synchronized;


/**
 *  删除array，可选择自带事务或者自行在外层包裹事务
 *
 *  @param objects description
 *  @param useTransaction 若外层有事务，请用NO，若没有，请用YES
 */
- (BOOL)jr_deleteObjects:(NSArray<id<JRPersistent>> *)objects useTransaction:(BOOL)useTransaction synchronized:(BOOL)synchronized;


#pragma mark  delete all

- (BOOL)jr_deleteAll:(Class<JRPersistent>)clazz useTransaction:(BOOL)useTransaction synchronized:(BOOL)synchronized;


#pragma mark  save or update

- (BOOL)jr_saveOrUpdateOne:(id<JRPersistent>)one useTransaction:(BOOL)useTransaction synchronized:(BOOL)synchronized;

- (BOOL)jr_saveOrUpdateObjects:(NSArray<id<JRPersistent>> *)objects useTransaction:(BOOL)useTransaction synchronized:(BOOL)synchronized;


#pragma mark  query

- (NSArray<id<JRPersistent>> *)jr_getByJRSql:(JRSql *)sql sync:(BOOL)sync resultClazz:(Class<JRPersistent>)clazz columns:(NSArray * _Nullable)columns;

/**
 *  根据primarykey获取对象
 *
 *  @param primaryKey 主键
 *  @param clazz      类
 *
 */
- (id<JRPersistent> _Nullable)jr_getByPrimaryKey:(id)primaryKey clazz:(Class<JRPersistent>)clazz synchronized:(BOOL)synchronized;


- (id<JRPersistent> _Nullable)jr_getByID:(NSString *)ID clazz:(Class<JRPersistent>)clazz synchronized:(BOOL)synchronized;

#pragma mark  convenience method

- (long)jr_count4PrimaryKey:(id)pk clazz:(Class<JRPersistent>)clazz synchronized:(BOOL)synchronized;


@end

/******************************************************************************/

#pragma mark - Recursive operations

@protocol JRPersistentRecursiveOperationsHandler <NSObject>

@required


/**
 删除数据库中的中间表垃圾数据

 */
- (void)jr_clearRubbinshData;

#pragma mark  save

/**
 *  关联保存保存one
 *
 *  @param one description
 */
- (BOOL)jr_saveOneRecursively:(id<JRPersistent>)one useTransaction:(BOOL)useTransaction synchronized:(BOOL)synchronized;

/**
 *  保存数组
 *
 *  @param objects description
 *  @param useTransaction 若外层有事务，请用NO，若没有，请用YES
 */
- (BOOL)jr_saveObjectsRecursively:(NSArray<id<JRPersistent>> *)objects useTransaction:(BOOL)useTransaction synchronized:(BOOL)synchronized;

#pragma mark  update


/**
 *  更新one
 *
 *  @param one description
 *  @param columns 需要更新的字段
 */
- (BOOL)jr_updateOneRecursively:(id<JRPersistent>)one columns:(NSArray<NSString *> * _Nullable)columns useTransaction:(BOOL)useTransaction synchronized:(BOOL)synchronized;


/**
 *  更新array
 *
 *  @param objects description
 *  @param columns 需要更新的字段
 *  @param useTransaction 若外层有事务，请用NO，若没有，请用YES
 */
- (BOOL)jr_updateObjectsRecursively:(NSArray<id<JRPersistent>> *)objects columns:(NSArray<NSString *> * _Nullable)columns useTransaction:(BOOL)useTransaction synchronized:(BOOL)synchronized;


#pragma mark  delete

/**
 *  删除one，可选择自带事务或者自行在外层包裹事务
 *
 *  @param one description
 *  @param useTransaction 若外层有事务，请用NO，若没有，请用YES
 */
- (BOOL)jr_deleteOneRecursively:(id<JRPersistent>)one useTransaction:(BOOL)useTransaction synchronized:(BOOL)synchronized;

/**
 *  删除array，可选择自带事务或者自行在外层包裹事务
 *
 *  @param objects description
 *  @param useTransaction 若外层有事务，请用NO，若没有，请用YES
 */
- (BOOL)jr_deleteObjectsRecursively:(NSArray<id<JRPersistent>> *)objects useTransaction:(BOOL)useTransaction synchronized:(BOOL)synchronized;

#pragma mark  delete all

- (BOOL)jr_deleteAllRecursively:(Class<JRPersistent>)clazz useTransaction:(BOOL)useTransaction synchronized:(BOOL)synchronized;


#pragma mark  save or update

- (BOOL)jr_saveOrUpdateOneRecursively:(id<JRPersistent>)one useTransaction:(BOOL)useTransaction synchronized:(BOOL)synchronized;

- (BOOL)jr_saveOrUpdateObjectsRecursively:(NSArray<id<JRPersistent>> *)objects useTransaction:(BOOL)useTransaction synchronized:(BOOL)synchronized;


#pragma mark  query

- (NSArray<id<JRPersistent>> *)jr_findByJRSql:(JRSql *)sql sync:(BOOL)sync resultClazz:(Class<JRPersistent>)clazz columns:(NSArray * _Nullable)columns;

- (id<JRPersistent> _Nullable)jr_findByPrimaryKey:(id)primaryKey clazz:(Class<JRPersistent>)clazz synchronized:(BOOL)synchronized;

- (id<JRPersistent> _Nullable)jr_findByID:(NSString *)ID clazz:(Class<JRPersistent>)clazz synchronized:(BOOL)synchronized;

@end

#pragma mark - JRPersistentHandler

@protocol JRPersistentHandler <JRPersistentBaseHandler, JRPersistentOperationsHandler, JRPersistentRecursiveOperationsHandler>

@end

NS_ASSUME_NONNULL_END

#endif /* JRPersistentHandler_h */
