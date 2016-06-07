//
//  JRMiddleTable.h
//  JRDB
//
//  Created by JMacMini on 16/6/6.
//  Copyright © 2016年 Jrwong. All rights reserved.
//



#import <Foundation/Foundation.h>
#import "JRPersistent.h"

@class FMDatabase;

/**
 *  用于保存多对多的关系
 */
@interface JRMiddleTable : NSObject

@property (nonatomic, readonly, strong, nonnull) Class<JRPersistent> clazz1;
@property (nonatomic, readonly, strong, nonnull) Class<JRPersistent> clazz2;

@property (nonatomic, readonly, strong, nonnull) FMDatabase *db;

/**
 *  创建中建表对象
 *
 *  @param clazz1
 *  @param clazz2
 *  @param db
 */
+ (instancetype _Nullable)table4Clazz:(Class<JRPersistent> _Nonnull)clazz1 andClazz:(Class<JRPersistent> _Nonnull)clazz2 db:(FMDatabase * _Nonnull)db;

- (NSString * _Nonnull)tableName;

/**
 *  查询另一个关联类的ID数组
 *
 *  @param ID    id
 *  @param clazz 指定类
 *
 *  @return 另一个类的id数组
 */
- (NSArray<NSString *> * _Nonnull)anotherClazzIDsWithID:(NSString * _Nonnull)ID clazz:(Class<JRPersistent> _Nonnull)clazz;

/**
 *  保存关系数据 一对多 外界必须包含事务 执行完方法后需要commit
 *  （把之前的关系全删了，重新保存）
 *
 *  @param IDs       一对多 多方的ids
 *  @param withClazz 多方的class
 *  @param ID        一对多 单方的id
 *  @param IDClazz   单方的class
 *
 *  @return 结果
 */
- (BOOL)saveIDs:(NSArray<NSString *> * _Nonnull)IDs withClazz:(Class<JRPersistent> _Nonnull)withClazz forID:(NSString * _Nonnull)ID withIDClazz:(Class<JRPersistent> _Nonnull)IDClazz;

/**
 *  对JRPersistent的封装
 *  （把之前的关系全删了，重新保存）
 *
 *  @param objs
 *  @param obj
 *
 *  @return 
 */
- (BOOL)saveObjs:(NSArray<id<JRPersistent>> * _Nonnull)objs forObj:(id<JRPersistent> _Nonnull)obj;


- (BOOL)deleteID:(NSString * _Nonnull)ID forClazz:(Class<JRPersistent> _Nonnull)clazz;


- (BOOL)cleanRubbishData;

@end




