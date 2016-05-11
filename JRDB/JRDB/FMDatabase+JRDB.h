//
//  FMDatabase+JRDB.h
//  JRDB
//
//  Created by JMacMini on 16/5/10.
//  Copyright © 2016年 Jrwong. All rights reserved.
//

#import <FMDB/FMDB.h>
#import "JRPersistent.h"

@interface FMDatabase (JRDB)

/**
 *  使用block来进行队列操作，线程安全
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
- (void)createTable4Clazz:(Class<JRPersistent>)clazz;
/**
 *  更新表操作
 *  (只会添加字段，不会删除和更改字段类型)
 *  @param clazz 对应表的类
 */
- (void)updateTable4Clazz:(Class<JRPersistent>)clazz;
/**
 *  删除表
 *
 *  @param clazz 对应表的类
 */
- (void)deleteTable4Clazz:(Class<JRPersistent>)clazz;

#pragma mark - 增删改查操作
- (BOOL)saveObj:(id<JRPersistent>)obj;
- (BOOL)deleteObj:(id<JRPersistent>)obj;
/**
 *  更新操作（全量更新）
 *
 *  @param obj 更新的对象
 *
 *  @return 是否成功
 */
- (BOOL)updateObj:(id<JRPersistent>)obj;
/**
 *  更新操作
 *
 *  @param obj     部分更新
 *  @param columns 需要更新的字段数组（全称）
 *
 *  @return 是否成功
 */
- (BOOL)updateObj:(id<JRPersistent>)obj columns:(NSArray *)columns;

- (id<JRPersistent>)getByID:(NSString *)ID clazz:(Class<JRPersistent>)clazz;

- (NSArray *)findAll:(Class<JRPersistent>)clazz;
- (NSArray *)findAll:(Class<JRPersistent>)clazz orderBy:(NSString *)orderby isDesc:(BOOL)isDesc;

@end
