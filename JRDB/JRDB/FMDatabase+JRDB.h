//
//  FMDatabase+JRDB.h
//  JRDB
//
//  Created by JMacMini on 16/5/10.
//  Copyright © 2016年 Jrwong. All rights reserved.
//

//#import <FMDB/FMDB.h>
#import "JRPersistent.h"
#import "JRColumnSchema.h"

@import FMDB;

@class JRQueryCondition;

@interface FMDatabase (JRDB)

#pragma mark - queue operation

- (FMDatabaseQueue * _Nonnull)databaseQueue;

- (void)closeQueue;

/**
 *  使用block来进行队列操作，后台操作，线程安全
 *
 *  @param block 执行block
 */
- (void)inQueue:(void (^ _Nonnull)(FMDatabase * _Nonnull db))block;
/**
 *  事物回滚操作
 *
 *  @param block 执行block
 */
- (BOOL)inTransaction:(void (^ _Nonnull)(FMDatabase * _Nonnull db, BOOL * _Nonnull rollBack))block;

#pragma mark - table operation

/**
 *  建表操作
 *
 *  @param clazz 对应表的类
 */
- (BOOL)createTable4Clazz:(Class<JRPersistent> _Nonnull)clazz;
- (void)createTable4Clazz:(Class<JRPersistent> _Nonnull)clazz complete:(JRDBComplete _Nullable)complete;


/**
 *  把表删了，重新创建
 *
 *  @param clazz 类
 *
 *  @return 是否成功
 */
- (BOOL)truncateTable4Clazz:(Class<JRPersistent> _Nonnull)clazz;
- (void)truncateTable4Clazz:(Class<JRPersistent> _Nonnull)clazz complete:(JRDBComplete _Nullable)complete;


/**
 *  更新表操作
 *  (只会添加字段，不会删除和更改字段类型)
 *  @param clazz 对应表的类
 */
- (BOOL)updateTable4Clazz:(Class<JRPersistent> _Nonnull)clazz;
- (void)updateTable4Clazz:(Class<JRPersistent> _Nonnull)clazz complete:(JRDBComplete _Nullable)complete;

/**
 *  删除表
 *
 *  @param clazz 对应表的类
 */
- (BOOL)dropTable4Clazz:(Class<JRPersistent> _Nonnull)clazz;
- (void)dropTable4Clazz:(Class<JRPersistent> _Nonnull)clazz complete:(JRDBComplete _Nullable)complete;

#pragma mark - table message 

- (NSArray<JRColumnSchema *> * _Nonnull)schemasInClazz:(Class<JRPersistent> _Nonnull)clazz;

#pragma mark - 增删改查操作
/**
 *  save 操作，若使用默认主键，则自动生成主键，若自定义主键，需要自行赋值主键
 *  因为带有关联保存操作，自带事务操作
 *
 *  @param obj 保存对象
 *  @return return value description
 */
- (BOOL)saveObj:(id<JRPersistent> _Nonnull)obj;
- (void)saveObj:(id<JRPersistent> _Nonnull)obj complete:(JRDBComplete _Nullable)complete;

/**
 *  save 操作，若使用默认主键，则自动生成主键，若自定义主键，需要自行赋值主键
 *  因为带有关联保存操作，自带事务操作
 *
 *  @param obj 保存对象
 *  @param useTransaction 是否使用事务，可以选择使用，也可以选择自行包裹事务
 *  @return return value description
 */

- (BOOL)saveObj:(id<JRPersistent> _Nonnull)obj useTransaction:(BOOL)useTransaction;
- (void)saveObj:(id<JRPersistent> _Nonnull)obj useTransaction:(BOOL)useTransaction complete:(JRDBComplete _Nullable)complete;

/**
 *  删除操作
 *
 *  @param obj 删除的对象
 *
 *  @return 结果
 */
- (BOOL)deleteObj:(id<JRPersistent> _Nonnull)obj;
- (void)deleteObj:(id<JRPersistent> _Nonnull)obj complete:(JRDBComplete _Nullable)complete;

- (BOOL)deleteAll:(Class<JRPersistent> _Nonnull)clazz;
- (void)deleteAll:(Class<JRPersistent> _Nonnull)clazz complete:(JRDBComplete _Nullable)complete;

/**
 *  更新操作（全量更新）
 *
 *  @param obj 更新的对象
 *
 *  @return 是否成功
 */
- (BOOL)updateObj:(id<JRPersistent> _Nonnull)obj;
- (void)updateObj:(id<JRPersistent> _Nonnull)obj complete:(JRDBComplete _Nullable)complete;

/**
 *  更新操作
 *
 *  @param obj     部分更新
 *  @param columns 需要更新的字段数组（全称）
 *
 *  @return 是否成功
 */
- (BOOL)updateObj:(id<JRPersistent> _Nonnull)obj columns:(NSArray * _Nullable)columns;
- (void)updateObj:(id<JRPersistent> _Nonnull)obj columns:(NSArray * _Nullable)columns complete:(JRDBComplete _Nullable)complete;

#pragma mark - single level query operation

/**
 *  根据ID查询，不关联查询，只查询一级
 *
 *  @param ID    id
 *  @param clazz class
 *
 *  @return obj
 */
- (id<JRPersistent> _Nullable)getByID:(NSString * _Nonnull)ID clazz:(Class<JRPersistent> _Nonnull)clazz;


/**
 *  根据指定主键进行查找，若已实现自定义主键，则根据自定义主键，若无，则根据默认主键『_ID』查找 ,不关联查询，只查询一级
 *
 *  @param primaryKey 主键
 *  @param clazz      类
 *
 *  @return 结果
 */
- (id<JRPersistent> _Nullable)getByPrimaryKey:(id _Nonnull)primaryKey clazz:(Class<JRPersistent> _Nonnull)clazz;

/**
 *  查找全部，不关联查询，只查询一级
 *
 *  @param clazz   class
 *  @param orderby 排序字段
 *  @param isDesc  是否倒序
 *
 *  @return 结果
 */
- (NSArray * _Nonnull)getAll:(Class<JRPersistent> _Nonnull)clazz orderBy:(NSString * _Nullable)orderby isDesc:(BOOL)isDesc;

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
- (NSArray<id<JRPersistent>> * _Nonnull)getByConditions:(NSArray<JRQueryCondition *> * _Nullable)conditions clazz:(Class<JRPersistent> _Nonnull)clazz groupBy:(NSString * _Nullable)groupBy orderBy:(NSString * _Nullable)orderBy limit:(NSString * _Nullable)limit isDesc:(BOOL)isDesc;

#pragma mark - multi level query operation

/**
 *  根据默认主键『_ID』 进行查找 若有关联数据，一并查询
 *
 *  @param ID    ID
 *  @param clazz 类
 *
 *  @return 结果
 */
- (id<JRPersistent> _Nullable)findByID:(NSString * _Nonnull)ID clazz:(Class<JRPersistent> _Nonnull)clazz;

/**
 *  根据指定主键进行查找，若已实现自定义主键，则根据自定义主键，若无，则根据默认主键『_ID』查找 若有关联数据，一并查询
 *
 *  @param primaryKey 主键
 *  @param clazz      类
 *
 *  @return 结果
 */
- (id<JRPersistent> _Nullable)findByPrimaryKey:(id _Nonnull)primaryKey clazz:(Class<JRPersistent> _Nonnull)clazz;

- (NSArray<id<JRPersistent>> * _Nonnull)findAll:(Class<JRPersistent> _Nonnull)clazz;
- (NSArray<id<JRPersistent>> * _Nonnull)findAll:(Class<JRPersistent> _Nonnull)clazz orderBy:(NSString * _Nullable)orderby isDesc:(BOOL)isDesc;

/**
 *  根据条件查询(条件名称需要是属性全称)
 *
 *  @param conditions 条件语句 类似 『name like '00%'』 『age > 10』 『date > '2014-10-11'』
 *
 *  @return 查询结果
 */
- (NSArray<id<JRPersistent>> * _Nonnull)findByConditions:(NSArray<JRQueryCondition *> * _Nullable)conditions clazz:(Class<JRPersistent> _Nonnull)clazz groupBy:(NSString * _Nullable)groupBy orderBy:(NSString * _Nullable)orderBy limit:(NSString * _Nullable)limit isDesc:(BOOL)isDesc;

/**
 *  单纯根据条件查询
 */
- (NSArray<id<JRPersistent>> * _Nonnull)findByConditions:(NSArray<JRQueryCondition *> * _Nullable)conditions clazz:(Class<JRPersistent> _Nonnull)clazz isDesc:(BOOL)isDesc;

/**
 *  单纯根据groupby以及条件
 */
- (NSArray<id<JRPersistent>> * _Nonnull)findByConditions:(NSArray<JRQueryCondition *> * _Nullable)conditions clazz:(Class<JRPersistent> _Nonnull)clazz groupBy:(NSString * _Nullable)groupBy isDesc:(BOOL)isDesc;

/**
 *  单纯根据orderby以及条件
 */
- (NSArray<id<JRPersistent>> * _Nonnull)findByConditions:(NSArray<JRQueryCondition *> * _Nullable)conditions clazz:(Class<JRPersistent> _Nonnull)clazz orderBy:(NSString * _Nullable)orderBy isDesc:(BOOL)isDesc;

/**
 *  单纯根据limit以及条件
 */
- (NSArray<id<JRPersistent>> * _Nonnull)findByConditions:(NSArray<JRQueryCondition *> * _Nullable)conditions clazz:(Class<JRPersistent> _Nonnull)clazz limit:(NSString * _Nullable)limit isDesc:(BOOL)isDesc;

#pragma mark - convenience method

/**
 *  检查对应类的表是否存在
 *
 *  @param clazz 类
 *
 *  @return 是否存在
 */
- (BOOL)checkExistsTable4Clazz:(Class<JRPersistent> _Nonnull)clazz;



@end
