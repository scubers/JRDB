//
//  FMDatabase+JRPersistentHandler.h
//  JRDB
//
//  Created by J on 2016/10/25.
//  Copyright © 2016年 Jrwong. All rights reserved.
//

#import <FMDB/FMDB.h>
#import "JRPersistentHandler.h"

@interface FMDatabase (JRPersistentHandler) <JRPersistentHandler>

@end

@interface FMDatabase (JRPersistentHandlerRecurively)


#pragma mark - save

/**
 *  关联保存保存one
 *
 *  @param one
 */
- (BOOL)jr_saveOneRecursively:(id<JRPersistent> _Nonnull)one useTransaction:(BOOL)useTransaction synchronized:(BOOL)synchronized;

/**
 *  保存数组
 *
 *  @param objects
 *  @param useTransaction 若外层有事务，请用NO，若没有，请用YES
 */
- (BOOL)jr_saveObjectsRecursively:(NSArray<id<JRPersistent>> * _Nonnull)objects useTransaction:(BOOL)useTransaction synchronized:(BOOL)synchronized;
#pragma mark - update


/**
 *  更新one
 *
 *  @param one
 *  @param columns 需要更新的字段
 */
- (BOOL)jr_updateOneRecursively:(id<JRPersistent> _Nonnull)one columns:(NSArray<NSString *> * _Nullable)columns useTransaction:(BOOL)useTransaction synchronized:(BOOL)synchronized;


/**
 *  更新array
 *
 *  @param objects
 *  @param columns 需要更新的字段
 *  @param useTransaction 若外层有事务，请用NO，若没有，请用YES
 */
- (BOOL)jr_updateObjectsRecursively:(NSArray<id<JRPersistent>> * _Nonnull)objects columns:(NSArray<NSString *> * _Nullable)columns useTransaction:(BOOL)useTransaction synchronized:(BOOL)synchronized;


#pragma mark - delete

/**
 *  删除one，可选择自带事务或者自行在外层包裹事务
 *
 *  @param one
 *  @param useTransaction 若外层有事务，请用NO，若没有，请用YES
 */
- (BOOL)jr_deleteOneRecursively:(id<JRPersistent> _Nonnull)one useTransaction:(BOOL)useTransaction synchronized:(BOOL)synchronized;

/**
 *  删除array，可选择自带事务或者自行在外层包裹事务
 *
 *  @param objects
 *  @param useTransaction 若外层有事务，请用NO，若没有，请用YES
 */
- (BOOL)jr_deleteObjectsRecursively:(NSArray<id<JRPersistent>> * _Nonnull)objects useTransaction:(BOOL)useTransaction synchronized:(BOOL)synchronized;

#pragma mark - delete all

- (BOOL)jr_deleteAllRecursively:(Class<JRPersistent> _Nonnull)clazz useTransaction:(BOOL)useTransaction synchronized:(BOOL)synchronized;


#pragma mark - save or update

- (BOOL)jr_saveOrUpdateOneRecursively:(id<JRPersistent> _Nonnull)one useTransaction:(BOOL)useTransaction synchronized:(BOOL)synchronized;

- (BOOL)jr_saveOrUpdateObjectsRecursively:(NSArray<id<JRPersistent>> * _Nonnull)objects useTransaction:(BOOL)useTransaction synchronized:(BOOL)synchronized;


#pragma mark - query

- (NSArray<id<JRPersistent>> * _Nonnull)jr_findByJRSql:(JRSql * _Nonnull)sql sync:(BOOL)sync resultClazz:(Class<JRPersistent> _Nonnull)clazz columns:(NSArray * _Nullable)columns;

- (id<JRPersistent> _Nullable)jr_findByPrimaryKey:(id _Nonnull)primaryKey clazz:(Class<JRPersistent> _Nonnull)clazz synchronized:(BOOL)synchronized;

- (id<JRPersistent> _Nullable)jr_findByID:(NSString * _Nonnull)ID clazz:(Class<JRPersistent> _Nonnull)clazz synchronized:(BOOL)synchronized;


@end

