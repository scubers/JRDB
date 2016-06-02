//
//  NSObject+JRDB.h
//  JRDB
//
//  Created by JMacMini on 16/5/10.
//  Copyright © 2016年 Jrwong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JRPersistent.h"
#import "JRQueryCondition.h"

@class FMDatabase;

@interface NSObject (JRDB) <JRPersistent, JRIgnore>

#pragma mark - save
/**
 *  保存到指定数据库
 *
 *  @param db 数据库
 *
 *  @return 是否成功
 */
- (BOOL)jr_saveToDB:(FMDatabase * _Nonnull)db;
- (void)jr_saveToDB:(FMDatabase * _Nonnull)db complete:(JRDBComplete _Nullable)complete;
/**
 *  保存到JRDBMgr的默认数据库
 *
 *  @return 是否成功
 */
- (BOOL)jr_save;
- (void)jr_saveWithComplete:(JRDBComplete _Nullable)complete;

#pragma mark - update
/**
 *  更新到JRDBMgr默认数据库
 *  @param columns 指定更新列，nil为全量更新
 *  @return 是否成功
 */
- (BOOL)jr_updateWithColumn:(NSArray * _Nullable)columns;
- (void)jr_updateWithColumn:(NSArray * _Nullable)columns Complete:(JRDBComplete _Nullable)complete;

/**
 *  更新到指定数据库
 *
 *  @param db 数据库
 *  @param columns 指定更新列，nil为全量更新
 *  @return 是否成功
 */
- (BOOL)jr_updateToDB:(FMDatabase * _Nonnull)db column:(NSArray * _Nullable)columns;
- (void)jr_updateToDB:(FMDatabase * _Nonnull)db column:(NSArray * _Nullable)columns complete:(JRDBComplete _Nullable)complete;

#pragma mark - delete
/**
 *  从指定数据库删除
 *
 *  @param db 数据库
 *
 *  @return 是否成功
 */
- (BOOL)jr_deleteFromDB:(FMDatabase * _Nonnull)db;
- (void)jr_deleteFromDB:(FMDatabase * _Nonnull)db complete:(JRDBComplete _Nullable)complete;
/**
 *  从JRDBMgr的默认数据库删除
 *
 *  @return 是否成功
 */
- (BOOL)jr_delete;
- (void)jr_deleteWithComplete:(JRDBComplete _Nullable)complete;

#pragma mark - select

+ (instancetype _Nullable)jr_findByPrimaryKey:(id _Nonnull)ID;
+ (instancetype _Nullable)jr_findByPrimaryKey:(id _Nonnull)ID fromDB:(FMDatabase * _Nonnull)db;


+ (NSArray<id<JRPersistent>> * _Nonnull)jr_findAll;
+ (NSArray<id<JRPersistent>> * _Nonnull)jr_findAllFromDB:(FMDatabase * _Nonnull)db;
+ (NSArray<id<JRPersistent>> * _Nonnull)jr_findAllOrderBy:(NSString * _Nullable)orderBy isDesc:(BOOL)isDesc;
+ (NSArray<id<JRPersistent>> * _Nonnull)jr_findAllFromDB:(FMDatabase * _Nonnull)db orderBy:(NSString * _Nullable)orderBy isDesc:(BOOL)isDesc;


+ (NSArray<id<JRPersistent>> * _Nonnull)jr_findByConditions:(NSArray<JRQueryCondition *> * _Nullable)conditions groupBy:(NSString * _Nullable)groupBy orderBy:(NSString * _Nullable)orderBy limit:(NSString * _Nullable)limit isDesc:(BOOL)isDesc fromDB:(FMDatabase * _Nullable)db;

+ (NSArray<id<JRPersistent>> * _Nonnull)jr_findByConditions:(NSArray<JRQueryCondition *> * _Nullable)conditions groupBy:(NSString * _Nullable)groupBy orderBy:(NSString * _Nullable)orderBy limit:(NSString * _Nullable)limit isDesc:(BOOL)isDesc;

#pragma mark - sql语句

/**
 *  因为直接返回对象，所以sql 请以 select * 开头
 *
 *  @param sql  sql: select * from Person where _ID = ?
 *  @param args 参数 @[@"111"]
 *
 *  @return 返回数组
 */
+ (NSArray<id<JRPersistent>> * _Nonnull)jr_executeSql:(NSString * _Nonnull)sql args:(NSArray * _Nullable)args;
+ (NSArray<id<JRPersistent>> * _Nonnull)jr_executeSql:(NSString * _Nonnull)sql args:(NSArray * _Nullable)args fromDB:(FMDatabase * _Nonnull)db;

/**
 *  返回条数
 *
 *  @param sql  select count(1) where age > ?
 *  @param args @[@10]
 *
 *  @return 数据条数
 */
+ (NSUInteger)jr_countForSql:(NSString * _Nonnull)sql args:(NSArray * _Nullable)args;
+ (NSUInteger)jr_countForSql:(NSString * _Nonnull)sql args:(NSArray * _Nullable)args fromDB:(FMDatabase * _Nonnull)db;

#pragma mark - table operation
+ (BOOL)jr_createTable;
+ (BOOL)jr_createTableInDB:(FMDatabase * _Nonnull)db;

+ (BOOL)jr_updateTable;
+ (BOOL)jr_updateTableInDB:(FMDatabase * _Nonnull)db;

+ (BOOL)jr_dropTable;
+ (BOOL)jr_dropTableInDB:(FMDatabase * _Nonnull)db;

+ (BOOL)jr_truncateTable;
+ (BOOL)jr_truncateTableInDB:(FMDatabase * _Nonnull)db;

#pragma mark - hooking
+ (void)jr_swizzleSetters4Clazz;
- (NSMutableArray * _Nullable)jr_changedArray;

@end