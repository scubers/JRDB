//
//  FMDatabase+JRDB.h
//  JRDB
//
//  Created by JMacMini on 16/5/10.
//  Copyright © 2016年 Jrwong. All rights reserved.
//

//#import <FMDB/FMDB.h>
#import "JRPersistent.h"

@import FMDB;

@class JRQueryCondition;

@interface FMDatabase (JRDB)


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
- (void)inTransaction:(void (^ _Nonnull)(FMDatabase * _Nonnull db, BOOL * _Nonnull rollBack))block;

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

#pragma mark - 增删改查操作
/**
 *  save 操作，若使用默认主键，则自动生成主键，若自定义主键，需要自行赋值主键
 *
 *  @param obj 保存对象
 *  @return return value description
 */
- (BOOL)saveObj:(id<JRPersistent> _Nonnull)obj;
- (void)saveObj:(id<JRPersistent> _Nonnull)obj complete:(JRDBComplete _Nullable)complete;

- (BOOL)deleteObj:(id<JRPersistent> _Nonnull)obj;
- (void)deleteObj:(id<JRPersistent> _Nonnull)obj complete:(JRDBComplete _Nullable)complete;

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

- (id<JRPersistent> _Nullable)findByPrimaryKey:(id _Nonnull)ID clazz:(Class<JRPersistent> _Nonnull)clazz;

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

/**
 *  检查对应类的表是否存在
 *
 *  @param clazz 类
 *
 *  @return 是否存在
 */
- (BOOL)checkExistsTable4Clazz:(Class<JRPersistent> _Nonnull)clazz;



@end
