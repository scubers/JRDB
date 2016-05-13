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

@interface NSObject (JRDB) <JRPersistent>

+ (NSArray *)jr_excludePropertyNames;

#pragma mark - save
/**
 *  保存到指定数据库
 *
 *  @param db 数据库
 *
 *  @return 是否成功
 */
- (BOOL)jr_saveToDB:(FMDatabase *)db;
- (void)jr_saveToDB:(FMDatabase *)db complete:(JRDBComplete)complete;
/**
 *  保存到JRDBMgr的默认数据库
 *
 *  @return 是否成功
 */
- (BOOL)jr_save;
- (void)jr_saveWithComplete:(JRDBComplete)complete;

#pragma mark - update
/**
 *  更新到JRDBMgr默认数据库
 *  @param columns 指定更新列，nil为全量更新
 *  @return 是否成功
 */
- (BOOL)jr_updateWithColumn:(NSArray *)columns;
- (void)jr_updateWithColumn:(NSArray *)columns Complete:(JRDBComplete)complete;

/**
 *  更新到指定数据库
 *
 *  @param db 数据库
 *  @param columns 指定更新列，nil为全量更新
 *  @return 是否成功
 */
- (BOOL)jr_updateToDB:(FMDatabase *)db column:(NSArray *)columns;
- (void)jr_updateToDB:(FMDatabase *)db column:(NSArray *)columns complete:(JRDBComplete)complete;

#pragma mark - delete
/**
 *  从指定数据库删除
 *
 *  @param db 数据库
 *
 *  @return 是否成功
 */
- (BOOL)jr_deleteFromDB:(FMDatabase *)db;
- (void)jr_deleteFromDB:(FMDatabase *)db complete:(JRDBComplete)complete;
/**
 *  从JRDBMgr的默认数据库删除
 *
 *  @return 是否成功
 */
- (BOOL)jr_delete;
- (void)jr_deleteWithComplete:(JRDBComplete)complete;

#pragma mark - select

+ (instancetype)jr_findByID:(NSString *)ID;
+ (instancetype)jr_findByID:(NSString *)ID fromDB:(FMDatabase *)db;


+ (NSArray<id<JRPersistent>> *)jr_findAll;
+ (NSArray<id<JRPersistent>> *)jr_findAllFromDB:(FMDatabase *)db;
+ (NSArray<id<JRPersistent>> *)jr_findAllOrderBy:(NSString *)orderBy isDesc:(BOOL)isDesc;
+ (NSArray<id<JRPersistent>> *)jr_findAllFromDB:(FMDatabase *)db orderBy:(NSString *)orderBy isDesc:(BOOL)isDesc;


+ (NSArray *)jr_findByConditions:(NSArray<JRQueryCondition *> *)conditions groupBy:(NSString *)groupBy orderBy:(NSString *)orderBy limit:(NSString *)limit isDesc:(BOOL)isDesc fromDB:(FMDatabase *)db;

+ (NSArray *)jr_findByConditions:(NSArray<JRQueryCondition *> *)conditions groupBy:(NSString *)groupBy orderBy:(NSString *)orderBy limit:(NSString *)limit isDesc:(BOOL)isDesc;



@end