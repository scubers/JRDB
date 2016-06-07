//
//  JRPersistent.h
//  JRDB
//
//  Created by JMacMini on 16/5/10.
//  Copyright © 2016年 Jrwong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JRReflectable.h"

#define EXE_BLOCK(block, ...) if(block){block(__VA_ARGS__);}

#define SingleLinkColumn(property) [NSString stringWithFormat:@"_single_link_%@", property]

@protocol JRPersistent <JRReflectable>

typedef void(^JRDBComplete)(BOOL success);
typedef void(^JRDBDidFinishBlock)(id<JRPersistent> _Nonnull obj);

@required
- (void)setID:(NSString * _Nullable)ID;
- (NSString * _Nullable)ID;

@optional

/**
 *  返回不用入库的对象字段数组
 *  The full property names that you want to ignore for persistent
 *
 *  @return array
 */
+ (NSArray * _Nullable)jr_excludePropertyNames;


/**
 *  返回需要关联入库的字段（一对一）
 *
 *  @return 返回需要关联的字段
 */
+ (NSDictionary<NSString *, Class<JRPersistent>> * _Nullable)jr_singleLinkedPropertyNames;


/**
 *  返回需要关联入库字段 （一对多）
 *
 *  @return {字段全名 ： 多方的Class}
 */
+ (NSDictionary<NSString *, Class<JRPersistent>> * _Nullable)jr_oneToManyLinkedPropertyNames;

/**
 *  返回自定义主键字段
 *
 *  @return 字段全名
 */
+ (NSString * _Nullable)jr_customPrimarykey;


/**
 *  返回自定义主键值
 *
 *  @return 主键值
 */
- (id _Nullable)jr_customPrimarykeyValue;


#pragma mark - operation

/**
 *  完成save 或者 update 会调用
 * （注意：如果有事务操作，也会在执行当前sql语句之后执行，即使之后有可能会被回滚）
 *
 *  @param block 代码块
 */
- (void)jr_addDidFinishBlock:(JRDBDidFinishBlock _Nullable)block forIdentifier:(NSString * _Nonnull)identifier;
- (void)jr_removeDidFinishBlockForIdentifier:(NSString * _Nonnull)identifier;


/**
 *  此方法不用自己调用，库会每次操作完调用一次
 */
- (void)jr_executeFinishBlocks;

#pragma mark - convenience
/**
 *  如果有自定义主键，则返回自定义主键key，例如 name，若没有实现，则返回默认主键key ： @"_ID"
 *
 *  @return 主键的字段名
 */
+ (NSString * _Nonnull)jr_primaryKey;


/**
 * 如果有自定义主键，则返回自定义主键的值，如果没有，则返回 [self ID]
 *
 *  @return 主键值
 */
- (id _Nullable)jr_primaryKeyValue;


/**
 *  本对象是否可以被save
 *  但不保证数据库中没有重复对象
 */
- (BOOL)jr_objCanBeSave;


@end

