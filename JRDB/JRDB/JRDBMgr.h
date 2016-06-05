//
//  JRDBMgr.h
//  JRDB
//
//  Created by JMacMini on 16/5/10.
//  Copyright © 2016年 Jrwong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JRPersistent.h"

@class FMDatabase;

@interface JRDBMgr : NSObject

@property (nonatomic, strong) FMDatabase * _Nullable defaultDB;

+ (instancetype _Nonnull)shareInstance;
+ (FMDatabase * _Nonnull)defaultDB;
- (FMDatabase * _Nullable)createDBWithPath:(NSString * _Nullable)path;
- (void)deleteDBWithPath:(NSString * _Nullable)path;

/**
 *  在这里注册的类，使用本框架的数据库将全部建有这些表
 *  @param clazz 类名
 */
- (void)registerClazzForUpdateTable:(Class<JRPersistent> _Nonnull)clazz;
- (NSArray<Class> * _Nonnull)registedClazz;

/**
 * 更新默认数据库的表（或者新建没有的表）
 * 更新的表需要在本类先注册
 */
- (void)updateDefaultDB;
- (void)updateDB:(FMDatabase * _Nonnull)db;


- (BOOL)isValidateClazz:(Class<JRPersistent> _Nonnull)clazz;

@end
