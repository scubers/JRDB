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

/**
 *  非关联
 */
- (BOOL)jr_saveOrUpdateOnly;
/**
 *  关联
 */
- (BOOL)jr_saveOrUpdate;

#pragma mark - save

/**
 *  非关联
 */
- (BOOL)jr_saveOnly;
/**
 *  关联
 */
- (BOOL)jr_save;


#pragma mark - update

/**
 *  非关联
 */
- (BOOL)jr_updateOnlyColumns:(NSArray<NSString *> * _Nullable)columns;
/**
 *  关联
 */
- (BOOL)jr_updateColumns:(NSArray<NSString *> * _Nullable)columns;

/**
 *  非关联
 */
- (BOOL)jr_updateOnlyIgnore:(NSArray<NSString *> * _Nullable)Ignore;
/**
 *  关联
 */
- (BOOL)jr_updateIgnore:(NSArray<NSString *> * _Nullable)Ignore;


#pragma mark - delete

/**
 *  非关联
 */
+ (BOOL)jr_deleteAllOnly;
/**
 *  关联
 */
+ (BOOL)jr_deleteAll;

/**
 *  非关联
 */
- (BOOL)jr_deleteOnly;
/**
 *  关联
 */
- (BOOL)jr_delete;

#pragma mark - select

/**
 *  关联查询
 *
 *  @param ID
 */
+ (instancetype _Nullable)jr_findByID:(NSString * _Nonnull)ID;

/**
 *  关联查询
 *
 *  @param primaryKey
 */
+ (instancetype _Nullable)jr_findByPrimaryKey:(id _Nonnull)primaryKey;

/**
 *  关联查询
 *
 *  @return
 */
+ (NSArray<id<JRPersistent>> * _Nonnull)jr_findAll;

/**
 *  非关联查询
 *
 *  @param ID
 *
 */
+ (instancetype _Nullable)jr_getByID:(NSString * _Nonnull)ID;

/**
 *  非关联查询
 *
 *  @param primaryKey
 */
+ (instancetype _Nullable)jr_getByPrimaryKey:(id _Nonnull)primaryKey;

/**
 *  非关联查询
 */
+ (NSArray<id<JRPersistent>> * _Nonnull)jr_getAll;



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
