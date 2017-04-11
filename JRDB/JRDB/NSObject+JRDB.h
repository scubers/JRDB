//
//  NSObject+JRDB.h
//  JRDB
//
//  Created by JMacMini on 16/5/10.
//  Copyright © 2016年 Jrwong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JRPersistent.h"

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (JRPersistent) <JRPersistent>

@end

/********************************************************/

@interface NSObject (JRDB)

/**
 *  注册的时候自动调用, 刷新 - [jr_activatedProperties];
 */
+ (void)jr_configure;

+ (NSArray<JRActivatedProperty *> *)jr_activatedProperties;

#pragma mark - convinence method

- (void)jr_setSingleLinkID:(NSString * _Nullable)ID forKey:(NSString *)key;
- (NSString * _Nullable)jr_singleLinkIDforKey:(NSString *)key;

- (void)jr_setParentLinkID:(NSString * _Nullable)ID forKey:(NSString *)key;
- (NSString * _Nullable)jr_parentLinkIDforKey:(NSString *)key;

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
 *  @param ID description
 */
+ (instancetype _Nullable)jr_findByID:(NSString *)ID;

/**
 *  关联查询
 *
 *  @param primaryKey description
 */
+ (instancetype _Nullable)jr_findByPrimaryKey:(id)primaryKey;

/**
 *  关联查询
 *
 *  @return 查询结果
 */
+ (NSArray<id<JRPersistent>> *)jr_findAll;

/**
 *  非关联查询
 *
 *  @param ID description
 *
 */
+ (instancetype _Nullable)jr_getByID:(NSString *)ID;

/**
 *  非关联查询
 *
 *  @param primaryKey description
 */
+ (instancetype _Nullable)jr_getByPrimaryKey:(id)primaryKey;

/**
 *  非关联查询
 */
+ (NSArray<id<JRPersistent>> *)jr_getAll;



#pragma mark - table operation

+ (BOOL)jr_createTable;

+ (BOOL)jr_updateTable;

+ (BOOL)jr_dropTable;

+ (BOOL)jr_truncateTable;


@end

NS_ASSUME_NONNULL_END
