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
 *  注册的时候自动调用, 刷新- [jr_activatedProperties];
 */
+ (void)jr_configure;

#pragma mark - convinence method

- (void)jr_setSingleLinkID:(NSString * _Nullable)ID forKey:(NSString * _Nonnull)key;
- (NSString * _Nullable)jr_singleLinkIDforKey:(NSString * _Nonnull)key;

- (void)jr_setParentLinkID:(NSString * _Nullable)ID forKey:(NSString * _Nonnull)key;
- (NSString * _Nullable)jr_parentLinkIDforKey:(NSString * _Nonnull)key;


- (NSMutableDictionary<NSString *,JRDBDidFinishBlock> * _Nonnull)jr_finishBlocks;

#pragma mark - save or update


- (BOOL)jr_saveOrUpdateOnly;
- (BOOL)jr_saveOrUpdate;

#pragma mark - save

/**
 *  仅保存自身，不进行关联保存（不建议使用）:使用默认数据库
 */
- (BOOL)jr_saveOnly;
- (BOOL)jr_save;


#pragma mark - update

/**
 *  仅更新自身，不进行关联保存（不建议使用）
 *
 *  @param columns 要更新的字段
 */
- (BOOL)jr_updateOnlyColumns:(NSArray<NSString *> * _Nullable)columns;
- (BOOL)jr_updateColumns:(NSArray<NSString *> * _Nullable)columns;

- (BOOL)jr_updateOnlyIgnore:(NSArray<NSString *> * _Nullable)Ignore;
- (BOOL)jr_updateIgnore:(NSArray<NSString *> * _Nullable)Ignore;


#pragma mark - delete

+ (BOOL)jr_deleteAllOnly;
+ (BOOL)jr_deleteAll;

/**
 *  仅删除自身，不进行关联保存（不建议使用）
 */
- (BOOL)jr_deleteOnly;
- (BOOL)jr_delete;

#pragma mark - select

+ (instancetype _Nullable)jr_findByID:(NSString * _Nonnull)ID;

+ (instancetype _Nullable)jr_findByPrimaryKey:(id _Nonnull)primaryKey;


+ (NSArray<id<JRPersistent>> * _Nonnull)jr_findAll;

#pragma mark - table operation
+ (BOOL)jr_createTable;

+ (BOOL)jr_updateTable;

+ (BOOL)jr_dropTable;

+ (BOOL)jr_truncateTable;

#pragma mark - table message

+ (NSArray<NSString *> * _Nonnull)jr_currentColumns;

#pragma mark - hooking
+ (void)jr_swizzleSetters4Clazz;
- (NSMutableArray * _Nullable)jr_changedArray;


@end