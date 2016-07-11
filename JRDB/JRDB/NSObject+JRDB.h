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

#define JR_DEFAULTDB [JRDBMgr defaultDB]

@class FMDatabase;

@interface NSObject (JRDB) <JRPersistent>

/**
 *  注册的时候自动调用, 每个注册类有且只执行一次;
 */
+ (void)jr_configure;

#pragma mark - convinence method

- (void)jr_setSingleLinkID:(NSString * _Nullable)ID forKey:(NSString * _Nonnull)key;
- (NSString * _Nullable)jr_singleLinkIDforKey:(NSString * _Nonnull)key;

- (void)jr_setParentLinkID:(NSString * _Nullable)ID forKey:(NSString * _Nonnull)key;
- (NSString * _Nullable)jr_parentLinkIDforKey:(NSString * _Nonnull)key;


- (NSMutableDictionary<NSString *,JRDBDidFinishBlock> * _Nonnull)jr_finishBlocks;

#pragma mark - save or update

- (BOOL)jr_saveOrUpdateOnlyToDB:(FMDatabase * _Nonnull)db;

/**
 *  保存或更新自身到db， 并进行关联保存删除更新
 *
 *  @param db
 *  @param useTransaction 若外层有事务，请用NO，若没有，请用YES
 */
- (BOOL)jr_saveOrUpdateUseTransaction:(BOOL)useTransaction toDB:(FMDatabase * _Nonnull)db;
- (void)jr_saveOrUpdateUseTransaction:(BOOL)useTransaction complete:(JRDBComplete _Nullable)complete  toDB:(FMDatabase * _Nonnull)db;

- (BOOL)jr_saveOrUpdateToDB:(FMDatabase * _Nonnull)db;
- (void)jr_saveOrUpdateWithComplete:(JRDBComplete _Nullable)complete toDB:(FMDatabase * _Nonnull)db;

#pragma mark - save or update use DefaultDB

- (BOOL)jr_saveOrUpdateUseTransaction:(BOOL)useTransaction;
- (void)jr_saveOrUpdateUseTransaction:(BOOL)useTransaction complete:(JRDBComplete _Nullable)complete;

- (BOOL)jr_saveOrUpdate;
- (void)jr_saveOrUpdateWithComplete:(JRDBComplete _Nullable)complete;

#pragma mark - save

/**
 *  仅保存自身，不进行关联保存（不建议使用）
 *
 *  @param db
 */
- (BOOL)jr_saveOnlyToDB:(FMDatabase * _Nonnull)db;

/**
 *  保存自身到db， 并进行关联保存删除更新
 *
 *  @param db
 *  @param useTransaction 若外层有事务，请用NO，若没有，请用YES
 */
- (BOOL)jr_saveUseTransaction:(BOOL)useTransaction toDB:(FMDatabase * _Nonnull)db;
- (void)jr_saveUseTransaction:(BOOL)useTransaction complete:(JRDBComplete _Nullable)complete  toDB:(FMDatabase * _Nonnull)db;

- (BOOL)jr_saveToDB:(FMDatabase * _Nonnull)db;
- (void)jr_saveWithComplete:(JRDBComplete _Nullable)complete toDB:(FMDatabase * _Nonnull)db;

#pragma mark - save use DefaultDB

/**
 *  仅保存自身，不进行关联保存（不建议使用）:使用默认数据库
 */
- (BOOL)jr_saveOnly;

/**
 *  保存自身到db， 并进行关联保存删除更新 :使用默认数据库
 *
 *  @param useTransaction 若外层有事务，请用NO，若没有，请用YES
 */
- (BOOL)jr_saveUseTransaction:(BOOL)useTransaction;
- (void)jr_saveUseTransaction:(BOOL)useTransaction complete:(JRDBComplete _Nullable)complete;

- (BOOL)jr_save;
- (void)jr_saveWithComplete:(JRDBComplete _Nullable)complete;


#pragma mark - update

/**
 *  仅更新自身，不进行关联保存（不建议使用）
 *
 *  @param db
 *  @param columns 要更新的字段
 */
- (BOOL)jr_updateOnlyColumns:(NSArray<NSString *> * _Nullable)columns toDB:(FMDatabase * _Nonnull)db;

/**
 *  更新自身到db， 并进行关联保存删除更新
 *
 *  @param db
 *  @param columns 要更新的字段
 *  @param useTransaction 若外层有事务，请用NO，若没有，请用YES
 */
- (BOOL)jr_updateColumns:(NSArray<NSString *> * _Nullable)columns
          useTransaction:(BOOL)useTransaction
                    toDB:(FMDatabase * _Nonnull)db;

- (void)jr_updateColumns:(NSArray<NSString *> * _Nullable)columns
          useTransaction:(BOOL)useTransaction
                complete:(JRDBComplete _Nullable)complete
                    toDB:(FMDatabase * _Nonnull)db;

- (BOOL)jr_updateColumns:(NSArray<NSString *> * _Nullable)columns
                    toDB:(FMDatabase * _Nonnull)db;

- (void)jr_updateColumns:(NSArray<NSString *> * _Nullable)columns
                complete:(JRDBComplete _Nullable)complete
                    toDB:(FMDatabase * _Nonnull)db;

#pragma mark - update use DefaultDB

/**
 *  仅更新自身，不进行关联保存（不建议使用）
 *
 *  @param columns 要更新的字段
 */
- (BOOL)jr_updateOnlyColumns:(NSArray<NSString *> * _Nullable)columns;

/**
 *  更新自身到db， 并进行关联保存删除更新
 *
 *  @param columns 要更新的字段
 *  @param useTransaction 若外层有事务，请用NO，若没有，请用YES
 */
- (BOOL)jr_updateColumns:(NSArray<NSString *> * _Nullable)columns useTransaction:(BOOL)useTransaction;
- (void)jr_updateColumns:(NSArray<NSString *> * _Nullable)columns useTransaction:(BOOL)useTransaction complete:(JRDBComplete _Nullable)complete;

- (BOOL)jr_updateColumns:(NSArray<NSString *> * _Nullable)columns;
- (void)jr_updateColumns:(NSArray<NSString *> * _Nullable)columns complete:(JRDBComplete _Nullable)complete;

#pragma mark - delete

+ (BOOL)jr_deleteAllOnlyFromDB:(FMDatabase * _Nonnull)db;

/**
 *  仅删除自身，不进行关联保存（不建议使用）
 *
 *  @param db
 */
- (BOOL)jr_deleteOnlyFromDB:(FMDatabase * _Nonnull)db;

/**
 *  删除自身， 并进行关联保存删除更新
 *
 *  @param db
 *  @param useTransaction 若外层有事务，请用NO，若没有，请用YES
 */
- (BOOL)jr_deleteUseTransaction:(BOOL)useTransaction fromDB:(FMDatabase * _Nonnull)db;
- (void)jr_deleteUseTransaction:(BOOL)useTransaction complete:(JRDBComplete _Nullable)complete fromDB:(FMDatabase * _Nonnull)db;

- (BOOL)jr_deleteFromDB:(FMDatabase * _Nonnull)db;
- (void)jr_deleteWithComplete:(JRDBComplete _Nullable)complete fromDB:(FMDatabase * _Nonnull)db;

#pragma mark - delete use DefaultDB

+ (BOOL)jr_deleteAllOnly;

/**
 *  仅删除自身，不进行关联保存（不建议使用）
 */
- (BOOL)jr_deleteOnly;

/**
 *  删除自身， 并进行关联保存删除更新
 *
 *  @param useTransaction 若外层有事务，请用NO，若没有，请用YES
 */
- (BOOL)jr_deleteUseTransaction:(BOOL)useTransaction;
- (void)jr_deleteUseTransaction:(BOOL)useTransaction complete:(JRDBComplete _Nullable)complete;

- (BOOL)jr_delete;
- (void)jr_deleteWithComplete:(JRDBComplete _Nullable)complete;

#pragma mark - select

+ (instancetype _Nullable)jr_findByID:(NSString * _Nonnull)ID;
+ (instancetype _Nullable)jr_findByID:(NSString * _Nonnull)ID fromDB:(FMDatabase * _Nonnull)db;


+ (instancetype _Nullable)jr_findByPrimaryKey:(id _Nonnull)primaryKey;
+ (instancetype _Nullable)jr_findByPrimaryKey:(id _Nonnull)primaryKey fromDB:(FMDatabase * _Nonnull)db;


+ (NSArray<id<JRPersistent>> * _Nonnull)jr_findAll;
+ (NSArray<id<JRPersistent>> * _Nonnull)jr_findAllFromDB:(FMDatabase * _Nonnull)db;
+ (NSArray<id<JRPersistent>> * _Nonnull)jr_findAllOrderBy:(NSString * _Nullable)orderBy isDesc:(BOOL)isDesc;
+ (NSArray<id<JRPersistent>> * _Nonnull)jr_findAllFromDB:(FMDatabase * _Nonnull)db orderBy:(NSString * _Nullable)orderBy isDesc:(BOOL)isDesc;


+ (NSArray<id<JRPersistent>> * _Nonnull)jr_findByConditions:(NSArray<JRQueryCondition *> * _Nullable)conditions groupBy:(NSString * _Nullable)groupBy orderBy:(NSString * _Nullable)orderBy limit:(NSString * _Nullable)limit isDesc:(BOOL)isDesc fromDB:(FMDatabase * _Nullable)db;

+ (NSArray<id<JRPersistent>> * _Nonnull)jr_findByConditions:(NSArray<JRQueryCondition *> * _Nullable)conditions groupBy:(NSString * _Nullable)groupBy orderBy:(NSString * _Nullable)orderBy limit:(NSString * _Nullable)limit isDesc:(BOOL)isDesc;

#pragma mark - table message 

+ (NSArray<NSString *> * _Nonnull)jr_currentColumnsInDB:(FMDatabase * _Nonnull)db;
+ (NSArray<NSString *> * _Nonnull)jr_currentColumns;

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


+ (BOOL)jr_executeUpdate:(NSString * _Nonnull)sql args:(NSArray * _Nullable)args;
+ (BOOL)jr_executeUpdate:(NSString * _Nonnull)sql args:(NSArray * _Nullable)args fromDB:(FMDatabase * _Nonnull)db;

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