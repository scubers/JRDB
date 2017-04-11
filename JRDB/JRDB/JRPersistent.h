//
//  JRPersistent.h
//  JRDB
//
//  Created by JMacMini on 16/5/10.
//  Copyright © 2016年 Jrwong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JRReflectable.h"


#define J(_prop_)              (((void)(NO && ((void)(@selector(_prop_)), NO)), @#_prop_))


#define JR_CUSTOM_PRIMARY_KEY(_key_) \
        + (NSString *)jr_customPrimarykey {\
            return ((void)(NO && ((void)([[[self alloc] init] _key_]), NO)), @#_key_);\
        }\
        - (id)jr_customPrimarykeyValue {\
            return [self valueForKey:@#_key_];\
        }

#define JR_CUSTOM_TABLE_NAME(_tableName_)\
        + (NSString *)jr_customTableName {\
            return @#_tableName_;\
        }


#define DBIDKey @"_ID"
#define isID(name) ([[name uppercaseString] isEqualToString:DBIDKey] || [[name uppercaseString] isEqualToString:DBIDKey])
#define SingleLinkColumn(property) [NSString stringWithFormat:@"_single_link_%@", property]
#define ParentLinkColumn(property) [NSString stringWithFormat:@"_parent_link_%@", property]

@class JRActivatedProperty, JRDBChain;

NS_ASSUME_NONNULL_BEGIN

@protocol JRPersistent <JRReflectable>

typedef void(^JRDBComplete)(BOOL success);
typedef void(^JRDBChainComplete)(JRDBChain * chain, id _Nullable result);
typedef void(^JRDBQueryComplete)(id _Nullable result);
typedef void(^JRDBDidFinishBlock)(id<JRPersistent> obj);

@required
- (void)setID:(NSString * _Nullable)ID;
- (NSString * _Nullable)ID;

+ (void)setRegistered:(BOOL)registered;
+ (BOOL)isRegistered;

@optional


/**
 自定义表名，若不实现，或者返回nil，则默认为类名

 @return 表名
 */
+ (NSString *)jr_customTableName;

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
 */
@property (nonatomic, strong, readonly) NSMutableDictionary<NSString *, JRDBDidFinishBlock> *jr_finishBlocks;

- (void)jr_addDidFinishBlock:(JRDBDidFinishBlock _Nullable)block forIdentifier:(NSString *)identifier;
- (void)jr_removeDidFinishBlockForIdentifier:(NSString *)identifier;


/**
 *  此方法不用自己调用，库会每次操作完调用一次
 */
- (void)jr_executeFinishBlocks;

/**
 返回属性名对应的数据库字段

 */
+ (NSDictionary<NSString *, NSString *> * _Nullable)jr_databaseNameMap;


/**
 *  在注册之后，才会有值
 *
 *  @return 返回处于激活状态的属性数组
 */
+ (NSArray<JRActivatedProperty *> * _Nullable)jr_activatedProperties;

#pragma mark - convenience

/**
 便捷方法 @see + [jr_tableName] 若jr_tableName未返回或者为空，则返回本类名为表名

 @return 表名
 */
+ (NSString *)jr_tableName;

/**
 *  如果有自定义主键，则返回自定义主键key，例如 name，若没有实现，则返回默认主键key ： @"_ID"
 *
 *  @return 主键的字段名
 */
+ (NSString *)jr_primaryKey;


/**
 * 如果有自定义主键，则返回自定义主键的值，如果没有，则返回 [self ID]
 *
 *  @return 主键值
 */
- (id _Nullable)jr_primaryKeyValue;


@end

NS_ASSUME_NONNULL_END
