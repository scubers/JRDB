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



/************************************************************************/

@protocol JRPersistentBaseHandler <NSObject>

@optional

- (id<JRPersistentOperationsHandler> _Nonnull)jr_getOperationHandler;
- (id<JRPersistentRecursiveOperationsHandler> _Nonnull)jr_getRecursiveOperationHandler;

#pragma mark - base operation

@required

- (NSString * _Nonnull)handlerIdentifier;

- (BOOL)jr_openSynchronized:(BOOL)synchronized;

- (BOOL)jr_closeSynchronized:(BOOL)synchronized;

/**
 使用block来进行队列操作，后台操作，线程安全

 @param block 执行block
 */
- (void)jr_inQueue:(void (^ _Nonnull)(id<JRPersistentBaseHandler> _Nonnull handler))block;

/**
 事物回滚操作

 @param block 执行block
 */
- (BOOL)jr_inTransaction:(void (^ _Nonnull)(id<JRPersistentBaseHandler> _Nonnull handler, BOOL * _Nonnull rollBack))block;


/**
 您不会用到此方法, 擅自使用会造成数据库lock @see jr_inTransaction
 当前线程执行某个block, block 执行是必须有事务，useTransaction可以使用默认事务

 @param block
 @param useTransaction 是否使用默认事务 NO:需要自己开启和提交事务
 */
- (BOOL)jr_executeUseTransaction:(BOOL)useTransaction block:(BOOL (^ _Nonnull)(id<JRPersistentBaseHandler> _Nonnull handler))block;

/**
 任务是否同步执行

 @param sync  是否同步执行
 @param block

 */
- (id _Nullable)jr_executeSync:(BOOL)sync block:(id _Nullable (^ _Nonnull)(id<JRPersistentBaseHandler> _Nonnull handler))block;

/**
 执行sql 更新

 @param sql
 */
- (BOOL)jr_executeUpdate:(JRSql * _Nonnull)sql;

/**
 执行sql 查询

 @param sql
 */
- (id _Nonnull)jr_executeQuery:(JRSql * _Nonnull)sql;

@end


/*******************************************************/

@protocol JRPersistentOperationsHandler <NSObject>

@required

#pragma mark - table operation

/**
 *  建表操作
 *
 *  @param clazz 对应表的类
 */
- (BOOL)jr_createTable4Clazz:(Class<JRPersistent> _Nonnull)clazz synchronized:(BOOL)synchronized;


/**
 *  把表删了，重新创建
 *
 *  @param clazz 类
 *
 *  @return 是否成功
 */
- (BOOL)jr_truncateTable4Clazz:(Class<JRPersistent> _Nonnull)clazz synchronized:(BOOL)synchronized;


/**
 *  更新表操作
 *  (只会添加字段，不会删除和更改字段类型)
 *  @param clazz 对应表的类
 */
- (BOOL)jr_updateTable4Clazz:(Class<JRPersistent> _Nonnull)clazz synchronized:(BOOL)synchronized;

/**
 *  删除表
 *
 *  @param clazz 对应表的类
 */
- (BOOL)jr_dropTable4Clazz:(Class<JRPersistent> _Nonnull)clazz synchronized:(BOOL)synchronized;

/**
 *  检查对应类的表是否存在
 *
 *  @param clazz 类
 *
 *  @return 是否存在
 */
- (BOOL)jr_checkExistsTable4Clazz:(Class<JRPersistent> _Nonnull)clazz synchronized:(BOOL)synchronized;

#pragma mark - save

/**
 *  只保存one
 *
 *  @param one
 */
- (BOOL)jr_saveOne:(id<JRPersistent> _Nonnull)one useTransaction:(BOOL)useTransaction synchronized:(BOOL)synchronized;

/**
 *  保存数组
 *
 *  @param objects
 *  @param useTransaction 若外层有事务，请用NO，若没有，请用YES
 */
- (BOOL)jr_saveObjects:(NSArray<id<JRPersistent>> * _Nonnull)objects useTransaction:(BOOL)useTransaction synchronized:(BOOL)synchronized;

#pragma mark - update


/**
 *  更新one
 *
 *  @param one
 *  @param columns 需要更新的字段
 */
- (BOOL)jr_updateOne:(id<JRPersistent> _Nonnull)one columns:(NSArray<NSString *> * _Nullable)columns useTransaction:(BOOL)useTransaction synchronized:(BOOL)synchronized;


/**
 *  更新array
 *
 *  @param objects
 *  @param columns 需要更新的字段
 *  @param useTransaction 若外层有事务，请用NO，若没有，请用YES
 */
- (BOOL)jr_updateObjects:(NSArray<id<JRPersistent>> * _Nonnull)objects columns:(NSArray<NSString *> * _Nullable)columns useTransaction:(BOOL)useTransaction synchronized:(BOOL)synchronized;

#pragma mark - delete


/**
 *  删除one，可选择自带事务或者自行在外层包裹事务
 *
 *  @param one
 *  @param useTransaction 若外层有事务，请用NO，若没有，请用YES
 */
- (BOOL)jr_deleteOne:(id<JRPersistent> _Nonnull)one useTransaction:(BOOL)useTransaction synchronized:(BOOL)synchronized;


/**
 *  删除array，可选择自带事务或者自行在外层包裹事务
 *
 *  @param objects
 *  @param useTransaction 若外层有事务，请用NO，若没有，请用YES
 */
- (BOOL)jr_deleteObjects:(NSArray<id<JRPersistent>> * _Nonnull)objects useTransaction:(BOOL)useTransaction synchronized:(BOOL)synchronized;


#pragma mark - delete all

- (BOOL)jr_deleteAll:(Class<JRPersistent> _Nonnull)clazz useTransaction:(BOOL)useTransaction synchronized:(BOOL)synchronized;


#pragma mark - save or update

- (BOOL)jr_saveOrUpdateOne:(id<JRPersistent> _Nonnull)one useTransaction:(BOOL)useTransaction synchronized:(BOOL)synchronized;

- (BOOL)jr_saveOrUpdateObjects:(NSArray<id<JRPersistent>> * _Nonnull)objects useTransaction:(BOOL)useTransaction synchronized:(BOOL)synchronized;


#pragma mark - query

- (NSArray<id<JRPersistent>> * _Nonnull)jr_getByJRSql:(JRSql * _Nonnull)sql sync:(BOOL)sync resultClazz:(Class<JRPersistent> _Nonnull)clazz columns:(NSArray * _Nullable)columns;

/**
 *  根据primarykey获取对象
 *
 *  @param primaryKey 主键
 *  @param clazz      类
 *
 */
- (id<JRPersistent> _Nullable)jr_getByPrimaryKey:(id _Nonnull)primaryKey clazz:(Class<JRPersistent> _Nonnull)clazz synchronized:(BOOL)synchronized;


- (id<JRPersistent> _Nullable)jr_getByID:(NSString * _Nonnull)ID clazz:(Class<JRPersistent> _Nonnull)clazz synchronized:(BOOL)synchronized;

#pragma mark - convenience method

- (long)jr_count4PrimaryKey:(id _Nonnull)pk clazz:(Class<JRPersistent> _Nonnull)clazz synchronized:(BOOL)synchronized;


@end

/******************************************************************************/

@protocol JRPersistentRecursiveOperationsHandler <NSObject>

@required

#pragma mark - save

/**
 *  关联保存保存one
 *
 *  @param one
 */
- (BOOL)jr_saveOneRecursively:(id<JRPersistent> _Nonnull)one useTransaction:(BOOL)useTransaction synchronized:(BOOL)synchronized;

/**
 *  保存数组
 *
 *  @param objects
 *  @param useTransaction 若外层有事务，请用NO，若没有，请用YES
 */
- (BOOL)jr_saveObjectsRecursively:(NSArray<id<JRPersistent>> * _Nonnull)objects useTransaction:(BOOL)useTransaction synchronized:(BOOL)synchronized;
#pragma mark - update


/**
 *  更新one
 *
 *  @param one
 *  @param columns 需要更新的字段
 */
- (BOOL)jr_updateOneRecursively:(id<JRPersistent> _Nonnull)one columns:(NSArray<NSString *> * _Nullable)columns useTransaction:(BOOL)useTransaction synchronized:(BOOL)synchronized;


/**
 *  更新array
 *
 *  @param objects
 *  @param columns 需要更新的字段
 *  @param useTransaction 若外层有事务，请用NO，若没有，请用YES
 */
- (BOOL)jr_updateObjectsRecursively:(NSArray<id<JRPersistent>> * _Nonnull)objects columns:(NSArray<NSString *> * _Nullable)columns useTransaction:(BOOL)useTransaction synchronized:(BOOL)synchronized;


#pragma mark - delete

/**
 *  删除one，可选择自带事务或者自行在外层包裹事务
 *
 *  @param one
 *  @param useTransaction 若外层有事务，请用NO，若没有，请用YES
 */
- (BOOL)jr_deleteOneRecursively:(id<JRPersistent> _Nonnull)one useTransaction:(BOOL)useTransaction synchronized:(BOOL)synchronized;

/**
 *  删除array，可选择自带事务或者自行在外层包裹事务
 *
 *  @param objects
 *  @param useTransaction 若外层有事务，请用NO，若没有，请用YES
 */
- (BOOL)jr_deleteObjectsRecursively:(NSArray<id<JRPersistent>> * _Nonnull)objects useTransaction:(BOOL)useTransaction synchronized:(BOOL)synchronized;

#pragma mark - delete all

- (BOOL)jr_deleteAllRecursively:(Class<JRPersistent> _Nonnull)clazz useTransaction:(BOOL)useTransaction synchronized:(BOOL)synchronized;


#pragma mark - save or update

- (BOOL)jr_saveOrUpdateOneRecursively:(id<JRPersistent> _Nonnull)one useTransaction:(BOOL)useTransaction synchronized:(BOOL)synchronized;

- (BOOL)jr_saveOrUpdateObjectsRecursively:(NSArray<id<JRPersistent>> * _Nonnull)objects useTransaction:(BOOL)useTransaction synchronized:(BOOL)synchronized;


#pragma mark - query

- (NSArray<id<JRPersistent>> * _Nonnull)jr_findByJRSql:(JRSql * _Nonnull)sql sync:(BOOL)sync resultClazz:(Class<JRPersistent> _Nonnull)clazz columns:(NSArray * _Nullable)columns;

- (id<JRPersistent> _Nullable)jr_findByPrimaryKey:(id _Nonnull)primaryKey clazz:(Class<JRPersistent> _Nonnull)clazz synchronized:(BOOL)synchronized;

- (id<JRPersistent> _Nullable)jr_findByID:(NSString * _Nonnull)ID clazz:(Class<JRPersistent> _Nonnull)clazz synchronized:(BOOL)synchronized;

@end


@protocol JRPersistentHandler <JRPersistentBaseHandler, JRPersistentOperationsHandler, JRPersistentRecursiveOperationsHandler>

@end

#endif /* JRPersistentHandler_h */
