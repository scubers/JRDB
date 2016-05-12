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

typedef void(^JRDBComplete)(BOOL success);

@class JRQueryCondition;

@interface FMDatabase (JRDB)

/**
 *  使用block来进行队列操作，后台操作，线程安全
 *
 *  @param block 执行block
 */
- (void)inQueue:(void (^)(FMDatabase *db))block;
/**
 *  事物回滚操作
 *
 *  @param block 执行block
 */
- (void)inTransaction:(void (^)(FMDatabase *db, BOOL *rollBack))block;

/**
 *  建表操作
 *
 *  @param clazz 对应表的类
 */
- (BOOL)createTable4Clazz:(Class<JRPersistent>)clazz;
- (void)createTable4Clazz:(Class<JRPersistent>)clazz complete:(JRDBComplete)complete;

/**
 *  把表删了，重新创建
 *
 *  @param clazz 类
 *
 *  @return 是否成功
 */
- (BOOL)truncateTable4Clazz:(Class<JRPersistent>)clazz;
- (void)truncateTable4Clazz:(Class<JRPersistent>)clazz complete:(JRDBComplete)complete;

/**
 *  更新表操作
 *  (只会添加字段，不会删除和更改字段类型)
 *  @param clazz 对应表的类
 */
- (BOOL)updateTable4Clazz:(Class<JRPersistent>)clazz;
- (void)updateTable4Clazz:(Class<JRPersistent>)clazz complete:(JRDBComplete)complete;

/**
 *  删除表
 *
 *  @param clazz 对应表的类
 */
- (BOOL)dropTable4Clazz:(Class<JRPersistent>)clazz;
- (void)dropTable4Clazz:(Class<JRPersistent>)clazz complete:(JRDBComplete)complete;

#pragma mark - 增删改查操作
- (BOOL)saveObj:(id<JRPersistent>)obj;
- (void)saveObj:(id<JRPersistent>)obj complete:(JRDBComplete)complete;

- (BOOL)deleteObj:(id<JRPersistent>)obj;
- (void)deleteObj:(id<JRPersistent>)obj complete:(JRDBComplete)complete;

/**
 *  更新操作（全量更新）
 *
 *  @param obj 更新的对象
 *
 *  @return 是否成功
 */
- (BOOL)updateObj:(id<JRPersistent>)obj;
- (void)updateObj:(id<JRPersistent>)obj complete:(JRDBComplete)complete;

/**
 *  更新操作
 *
 *  @param obj     部分更新
 *  @param columns 需要更新的字段数组（全称）
 *
 *  @return 是否成功
 */
- (BOOL)updateObj:(id<JRPersistent>)obj columns:(NSArray *)columns;
- (void)updateObj:(id<JRPersistent>)obj columns:(NSArray *)columns complete:(JRDBComplete)complete;

- (id<JRPersistent>)getByID:(NSString *)ID clazz:(Class<JRPersistent>)clazz;

- (NSArray *)findAll:(Class<JRPersistent>)clazz;
- (NSArray *)findAll:(Class<JRPersistent>)clazz orderBy:(NSString *)orderby isDesc:(BOOL)isDesc;

/**
 *  根据条件查询(条件名称需要是属性全称)
 *
 *  @param conditions 条件语句 类似 『name like '00%'』 『age > 10』 『date > '2014-10-11'』
 *
 *  @return 查询结果
 */
- (NSArray *)findByConditions:(NSArray<JRQueryCondition *> *)conditions clazz:(Class<JRPersistent>)clazz groupBy:(NSString *)groupBy orderBy:(NSString *)orderBy limit:(NSString *)limit isDesc:(BOOL)isDesc;

/**
 *  单纯根据条件查询
 */
- (NSArray *)findByConditions:(NSArray<JRQueryCondition *> *)conditions clazz:(Class<JRPersistent>)clazz isDesc:(BOOL)isDesc;

/**
 *  单纯根据groupby以及条件
 */
- (NSArray *)findByConditions:(NSArray<JRQueryCondition *> *)conditions clazz:(Class<JRPersistent>)clazz groupBy:(NSString *)groupBy isDesc:(BOOL)isDesc;

/**
 *  单纯根据orderby以及条件
 */
- (NSArray *)findByConditions:(NSArray<JRQueryCondition *> *)conditions clazz:(Class<JRPersistent>)clazz orderBy:(NSString *)orderBy isDesc:(BOOL)isDesc;

/**
 *  单纯根据limit以及条件
 */
- (NSArray *)findByConditions:(NSArray<JRQueryCondition *> *)conditions clazz:(Class<JRPersistent>)clazz limit:(NSString *)limit isDesc:(BOOL)isDesc;

/**
 *  检查对应类的表是否存在
 *
 *  @param clazz 类
 *
 *  @return 是否存在
 */
- (BOOL)checkExistsTable4Clazz:(Class<JRPersistent>)clazz;



@end
