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

@property (nonatomic, readonly, strong) FMDatabase *defaultDB;

+ (instancetype)shareInstance;
+ (FMDatabase *)defaultDB;
- (FMDatabase *)createDBWithPath:(NSString *)path;
- (void)deleteDBWithPath:(NSString *)path;
- (FMDatabase *)DBWithPath:(NSString *)path;

/**
 *  在这里注册的类，使用本框架的数据库将全部建有这些表
 *  @param clazz 类名
 */
- (void)registerClazzForUpdateTable:(Class<JRPersistent>)clazz;
- (NSArray<Class> *)registedClazz;

/**
 * 更新默认数据库的表（或者新建没有的表）
 */
- (void)updateDefaultDB;

@end
