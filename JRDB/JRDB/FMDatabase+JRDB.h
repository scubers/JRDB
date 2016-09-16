//
//  FMDatabase+JRDB.h
//  JRDB
//
//  Created by JMacMini on 16/5/10.
//  Copyright © 2016年 Jrwong. All rights reserved.
//

#import "JRPersistent.h"
#import "JRColumnSchema.h"
#import <FMDB/FMDB.h>
#import "JRDBQueue.h"

@class JRQueryCondition, JRSql;

@interface FMDatabase (JRDB)

/**
 *  使用block来进行队列操作，后台操作，线程安全
 *
 *  @param block 执行block
 */
- (void)jr_inQueue:(void (^ _Nonnull)(FMDatabase * _Nonnull db))block;
/**
 *  事物回滚操作
 *
 *  @param block 执行block
 */
- (BOOL)jr_inTransaction:(void (^ _Nonnull)(FMDatabase * _Nonnull db, BOOL * _Nonnull rollBack))block;


/**
 *  您不会用到此方法, 擅自使用会造成数据库lock @see jr_inTransaction
 *  当前线程执行某个block, block 执行是必须有事务，useTransaction可以使用默认事务
 *
 *  @param block
 *  @param useTransaction 是否使用默认事务 NO:需要自己开启和提交事务
 */
- (BOOL)jr_execute:(BOOL (^ _Nonnull)(FMDatabase * _Nonnull db))block useTransaction:(BOOL)useTransaction;


- (id _Nullable)jr_executeSync:(BOOL)sync block:(id _Nullable (^ _Nonnull)(FMDatabase * _Nonnull db))block;


- (BOOL)jr_executeUpdate:(JRSql * _Nonnull)sql;
- (FMResultSet * _Nonnull)jr_executeQuery:(JRSql * _Nonnull)sql;


@end

#pragma mark - table operation

@interface FMDatabase (JRDBTable)


/**
 *  建表操作
 *
 *  @param clazz 对应表的类
 */
- (BOOL)jr_createTable4Clazz:(Class<JRPersistent> _Nonnull)clazz synchronized:(BOOL)synchronized complete:(JRDBComplete _Nullable)complete;


/**
 *  把表删了，重新创建
 *
 *  @param clazz 类
 *
 *  @return 是否成功
 */
- (BOOL)jr_truncateTable4Clazz:(Class<JRPersistent> _Nonnull)clazz synchronized:(BOOL)synchronized complete:(JRDBComplete _Nullable)complete;


/**
 *  更新表操作
 *  (只会添加字段，不会删除和更改字段类型)
 *  @param clazz 对应表的类
 */
- (BOOL)jr_updateTable4Clazz:(Class<JRPersistent> _Nonnull)clazz synchronized:(BOOL)synchronized complete:(JRDBComplete _Nullable)complete;

/**
 *  删除表
 *
 *  @param clazz 对应表的类
 */
- (BOOL)jr_dropTable4Clazz:(Class<JRPersistent> _Nonnull)clazz synchronized:(BOOL)synchronized complete:(JRDBComplete _Nullable)complete;

/**
 *  检查对应类的表是否存在
 *
 *  @param clazz 类
 *
 *  @return 是否存在
 */
- (BOOL)jr_checkExistsTable4Clazz:(Class<JRPersistent> _Nonnull)clazz;


#pragma mark - table message 

- (NSArray<JRColumnSchema *> * _Nonnull)jr_schemasInClazz:(Class<JRPersistent> _Nonnull)clazz;

@end

#pragma mark - save or update

@interface FMDatabase (JRDBSaveOrUpdate)


- (BOOL)jr_saveOrUpdateOneOnly:(id<JRPersistent> _Nonnull)one useTransaction:(BOOL)useTransaction synchronized:(BOOL)synchronized complete:(JRDBComplete _Nullable)complete;

- (BOOL)jr_saveOrUpdateOne:(id<JRPersistent> _Nonnull)one useTransaction:(BOOL)useTransaction synchronized:(BOOL)synchronized complete:(JRDBComplete _Nullable)complete;

#pragma mark - save or update array

- (BOOL)jr_saveOrUpdateObjectsOnly:(NSArray<id<JRPersistent>> * _Nonnull)objects useTransaction:(BOOL)useTransaction synchronized:(BOOL)synchronized complete:(JRDBComplete _Nullable)complete;

- (BOOL)jr_saveOrUpdateObjects:(NSArray<id<JRPersistent>> * _Nonnull)objects useTransaction:(BOOL)useTransaction synchronized:(BOOL)synchronized complete:(JRDBComplete _Nullable)complete;

@end

#pragma mark - save
@interface FMDatabase (JRDBSave)

/**
 *  只保存one，不进行关联保存和删除更新
 *
 *  @param one
 */
- (BOOL)jr_saveOneOnly:(id<JRPersistent> _Nonnull)one useTransaction:(BOOL)useTransaction synchronized:(BOOL)synchronized complete:(JRDBComplete _Nullable)complete;


/**
 *  保存one， 同时进行关联保存删除更新（建议使用），可选择自带事务或者自行在外层包裹事务
 *
 *  @param one
 *  @param useTransaction 若外层有事务，请用NO，若没有，请用YES
 */
- (BOOL)jr_saveOne:(id<JRPersistent> _Nonnull)one useTransaction:(BOOL)useTransaction synchronized:(BOOL)synchronized complete:(JRDBComplete _Nullable)complete;

#pragma mark - save array

- (BOOL)jr_saveObjectsOnly:(NSArray<id<JRPersistent>> * _Nonnull)objects useTransaction:(BOOL)useTransaction synchronized:(BOOL)synchronized complete:(JRDBComplete _Nullable)complete;


/**
 *  保存数组， 同时进行关联保存删除更新，可选择自带事务或者自行在外层包裹事务
 *
 *  @param objects
 *  @param useTransaction 若外层有事务，请用NO，若没有，请用YES
 */
- (BOOL)jr_saveObjects:(NSArray<id<JRPersistent>> * _Nonnull)objects useTransaction:(BOOL)useTransaction synchronized:(BOOL)synchronized complete:(JRDBComplete _Nullable)complete;

@end


#pragma mark - update
@interface FMDatabase (JRDBUpdate)

/**
 *  只更新one，不进行关联保存和删除更新
 *
 *  @param one
 *  @param columns 需要更新的字段
 */
- (BOOL)jr_updateOneOnly:(id<JRPersistent> _Nonnull)one columns:(NSArray<NSString *> * _Nullable)columns useTransaction:(BOOL)useTransaction synchronized:(BOOL)synchronized complete:(JRDBComplete _Nullable)complete;


/**
 *  更新one， 同时进行关联保存删除更新（建议使用），可选择自带事务或者自行在外层包裹事务
 *
 *  @param one
 *  @param columns 需要更新的字段
 *  @param useTransaction 若外层有事务，请用NO，若没有，请用YES
 */
- (BOOL)jr_updateOne:(id<JRPersistent> _Nonnull)one columns:(NSArray<NSString *> * _Nullable)columns useTransaction:(BOOL)useTransaction synchronized:(BOOL)synchronized complete:(JRDBComplete _Nullable)complete;


#pragma mark - update array

- (BOOL)jr_updateObjectsOnly:(NSArray<id<JRPersistent>> * _Nonnull)objects columns:(NSArray<NSString *> * _Nullable)columns useTransaction:(BOOL)useTransaction synchronized:(BOOL)synchronized complete:(JRDBComplete _Nullable)complete;


/**
 *  更新array， 同时进行关联保存删除更新，可选择自带事务或者自行在外层包裹事务
 *
 *  @param objects
 *  @param columns 需要更新的字段
 *  @param useTransaction 若外层有事务，请用NO，若没有，请用YES
 */
- (BOOL)jr_updateObjects:(NSArray<id<JRPersistent>> * _Nonnull)objects columns:(NSArray<NSString *> * _Nullable)columns useTransaction:(BOOL)useTransaction synchronized:(BOOL)synchronized complete:(JRDBComplete _Nullable)complete;

@end

#pragma mark - delete

@interface FMDatabase (JRDBDelete)

/**
 *  只删除one，不进行关联保存和删除更新
 *
 *  @param one
 */
- (BOOL)jr_deleteOneOnly:(id<JRPersistent> _Nonnull)one useTransaction:(BOOL)useTransaction synchronized:(BOOL)synchronized complete:(JRDBComplete _Nullable)complete;

/**
 *  删除one， 同时进行关联保存删除更新（建议使用），可选择自带事务或者自行在外层包裹事务
 *
 *  @param one
 *  @param useTransaction 若外层有事务，请用NO，若没有，请用YES
 */
- (BOOL)jr_deleteOne:(id<JRPersistent> _Nonnull)one useTransaction:(BOOL)useTransaction synchronized:(BOOL)synchronized complete:(JRDBComplete _Nullable)complete;

#pragma mark - delete array

- (BOOL)jr_deleteObjectsOnly:(NSArray<id<JRPersistent>> * _Nonnull)objects useTransaction:(BOOL)useTransaction synchronized:(BOOL)synchronized complete:(JRDBComplete _Nullable)complete;

/**
 *  删除array， 同时进行关联保存删除更新，可选择自带事务或者自行在外层包裹事务
 *
 *  @param objects
 *  @param useTransaction 若外层有事务，请用NO，若没有，请用YES
 */
- (BOOL)jr_deleteObjects:(NSArray<id<JRPersistent>> * _Nonnull)objects useTransaction:(BOOL)useTransaction synchronized:(BOOL)synchronized complete:(JRDBComplete _Nullable)complete;


#pragma mark - delete all

- (BOOL)jr_deleteAllOnly:(Class<JRPersistent> _Nonnull)clazz useTransaction:(BOOL)useTransaction synchronized:(BOOL)synchronized complete:(JRDBComplete _Nullable)complete;

- (BOOL)jr_deleteAll:(Class<JRPersistent> _Nonnull)clazz useTransaction:(BOOL)useTransaction synchronized:(BOOL)synchronized complete:(JRDBComplete _Nullable)complete;


@end

#pragma mark -  query

@interface FMDatabase (JRDBQuery)

/**
 *  根据ID查询，不关联查询，只查询一级
 *
 *  @param ID    id
 *  @param clazz class
 *
 *  @return obj
 */
- (id<JRPersistent> _Nullable)jr_getByID:(NSString * _Nonnull)ID
                                   clazz:(Class<JRPersistent> _Nonnull)clazz
                            synchronized:(BOOL)synchronized
                                useCache:(BOOL)useCache complete:(JRDBQueryComplete _Nullable)complete;


/**
 *  根据指定主键进行查找，若已实现自定义主键，则根据自定义主键，若无，则根据默认主键『_ID』查找 ,不关联查询，只查询一级
 *
 *  @param primaryKey 主键
 *  @param clazz      类
 *
 *  @return 结果
 */
- (id<JRPersistent> _Nullable)jr_getByPrimaryKey:(id _Nonnull)primaryKey
                                           clazz:(Class<JRPersistent> _Nonnull)clazz
                                    synchronized:(BOOL)synchronized
                                        complete:(JRDBQueryComplete _Nullable)complete;

/**
 *  根据条件查询，不关联查询，只查询一级
 *
 *  @param conditions 条件
 *  @param clazz      class
 *  @param groupBy    组字段
 *  @param orderBy    排序字段
 *  @param limit      分页条件
 *  @param isDesc     是否倒序
 *
 *  @return 结果
 */
- (NSArray<id<JRPersistent>> * _Nonnull)jr_getByConditions:(NSArray<JRQueryCondition *> * _Nullable)conditions
                                                     clazz:(Class<JRPersistent> _Nonnull)clazz
                                                   groupBy:(NSString * _Nullable)groupBy
                                                   orderBy:(NSString * _Nullable)orderBy
                                                     limit:(NSString * _Nullable)limit
                                                    isDesc:(BOOL)isDesc
                                              synchronized:(BOOL)synchronized
                                                  complete:(JRDBQueryComplete _Nullable)complete;

#pragma mark - multi level query operation

/**
 *  根据默认主键『_ID』 进行查找 若有关联数据，一并查询
 *
 *  @param ID    ID
 *  @param clazz 类
 *
 *  @return 结果
 */
- (id<JRPersistent> _Nullable)jr_findByID:(NSString * _Nonnull)ID
                                    clazz:(Class<JRPersistent> _Nonnull)clazz
                             synchronized:(BOOL)synchronized
                                 useCache:(BOOL)useCache
                                 complete:(JRDBQueryComplete _Nullable)complete;

/**
 *  根据指定主键进行查找，若已实现自定义主键，则根据自定义主键，若无，则根据默认主键『_ID』查找 若有关联数据，一并查询
 *
 *  @param primaryKey 主键
 *  @param clazz      类
 *
 *  @return 结果
 */
- (id<JRPersistent> _Nullable)jr_findByPrimaryKey:(id _Nonnull)primaryKey
                                            clazz:(Class<JRPersistent> _Nonnull)clazz
                                     synchronized:(BOOL)synchronized
                                         complete:(JRDBQueryComplete _Nullable)complete;

/**
 *  根据条件查询(条件名称需要是属性全称)
 *
 *  @param conditions 条件语句 类似 『name like '00%'』 『age > 10』 『date > '2014-10-11'』
 *
 *  @return 查询结果
 */
- (NSArray<id<JRPersistent>> * _Nonnull)jr_findByConditions:(NSArray<JRQueryCondition *> * _Nullable)conditions
                                                      clazz:(Class<JRPersistent> _Nonnull)clazz
                                                    groupBy:(NSString * _Nullable)groupBy
                                                    orderBy:(NSString * _Nullable)orderBy
                                                      limit:(NSString * _Nullable)limit
                                                     isDesc:(BOOL)isDesc
                                               synchronized:(BOOL)synchronized
                                                   useCache:(BOOL)useCache
                                                   complete:(JRDBQueryComplete _Nullable)complete;

#pragma mark - convenience method


- (long)jr_count4PrimaryKey:(id _Nonnull)pk clazz:(Class<JRPersistent> _Nonnull)clazz synchronized:(BOOL)synchronized complete:(JRDBQueryComplete _Nullable)complete;

- (long)jr_count4ID:(NSString * _Nonnull)ID clazz:(Class<JRPersistent> _Nonnull)clazz synchronized:(BOOL)synchronized complete:(JRDBQueryComplete _Nullable)complete;

- (NSArray<NSString *> * _Nonnull)jr_getIDsByConditions:(NSArray<JRQueryCondition *> * _Nullable)conditions
                                                  clazz:(Class<JRPersistent> _Nonnull)clazz
                                                groupBy:(NSString * _Nullable)groupBy
                                                orderBy:(NSString * _Nullable)orderBy
                                                  limit:(NSString * _Nullable)limit
                                                 isDesc:(BOOL)isDesc
                                           synchronized:(BOOL)synchronized
                                               complete:(JRDBQueryComplete _Nullable)complete;

@end

#pragma mark - cache

@interface FMDatabase (JRDBCache)

- (void)saveObjInRecursiveCache:(id<JRPersistent> _Nonnull)obj;

- (void)saveObjInUnRecursiveCache:(id<JRPersistent> _Nonnull)obj;

- (void)removeObjInRecursiveCache:(NSString * _Nonnull)ID;

- (void)removeObjInUnRecursiveCache:(NSString * _Nonnull)ID;

- (id<JRPersistent> _Nullable)objInRecursiveCache:(NSString * _Nonnull)ID;

- (id<JRPersistent> _Nullable)objInUnRecursiveCache:(NSString * _Nonnull)ID ;




@end

#pragma mark - JRSql

@interface FMDatabase (JRSql)

- (NSArray<id<JRPersistent>> * _Nonnull)jr_getByJRSql:(JRSql * _Nonnull)sql sync:(BOOL)sync resultClazz:(Class<JRPersistent> _Nonnull)clazz columns:(NSArray * _Nullable)columns;
- (NSArray<id<JRPersistent>> * _Nonnull)jr_findByJRSql:(JRSql * _Nonnull)sql sync:(BOOL)sync resultClazz:(Class<JRPersistent> _Nonnull)clazz columns:(NSArray * _Nullable)columns;

@end