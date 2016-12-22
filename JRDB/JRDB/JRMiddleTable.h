//
//  JRMiddleTable.h
//  JRDB
//
//  Created by JMacMini on 16/6/6.
//  Copyright © 2016年 Jrwong. All rights reserved.
//



#import <Foundation/Foundation.h>
#import "JRPersistent.h"
#import "JRPersistentHandler.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  用于保存多对多的关系
 */
@interface JRMiddleTable : NSObject

@property (nonatomic, readonly, strong) Class<JRPersistent> clazz1;
@property (nonatomic, readonly, strong) Class<JRPersistent> clazz2;

@property (nonatomic, readonly, strong) id<JRPersistentHandler> db;

/**
 *  创建中建表对象
 *
 *  @param clazz1 description
 *  @param clazz2 description
 *  @param db description
 */
+ (instancetype _Nullable)table4Clazz:(Class<JRPersistent>)clazz1 andClazz:(Class<JRPersistent>)clazz2 db:(id<JRPersistentHandler>)db;

- (NSString *)tableName;

/**
 *  查询另一个关联类的ID数组
 *
 *  @param ID    id
 *  @param clazz 指定类
 *
 *  @return 另一个类的id数组
 */
- (NSArray<NSString *> *)anotherClazzIDsWithID:(NSString *)ID clazz:(Class<JRPersistent>)clazz;

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
- (BOOL)saveIDs:(NSArray<NSString *> *)IDs withClazz:(Class<JRPersistent>)withClazz forID:(NSString *)ID withIDClazz:(Class<JRPersistent>)IDClazz;

/**
 *   对JRPersistent的封装
 *  （把之前的关系全删了，重新保存）
 *
 *  @param objs description
 *  @param obj description
 *
 *  @return description
 */
- (BOOL)saveObjs:(NSArray<id<JRPersistent>> *)objs forObj:(id<JRPersistent>)obj;


- (BOOL)deleteID:(NSString *)ID forClazz:(Class<JRPersistent>)clazz;

/**
 *  自身自带事务
 *
 *  @return description
 */
- (BOOL)cleanRubbishData;

@end

NS_ASSUME_NONNULL_END


