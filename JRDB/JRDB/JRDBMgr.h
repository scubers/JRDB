//
//  JRDBMgr.h
//  JRDB
//
//  Created by JMacMini on 16/5/10.
//  Copyright © 2016年 Jrwong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <FMDB.h>
#import "JRPersistent.h"

@interface JRDBMgr : NSObject

+ (instancetype)shareInstance;

- (BOOL)createDBWithPath:(NSString *)path;
- (BOOL)updateDBWithPath:(NSString *)path;
- (BOOL)deleteDBWithPath:(NSString *)path;
- (FMDatabase *)getDBWithPath:(NSString *)path;

- (BOOL)createTable4Clazz:(Class<JRPersistent>)clazz inDB:(FMDatabase *)db;
- (BOOL)updateTable4Clazz:(Class<JRPersistent>)clazz inDB:(FMDatabase *)db;
- (BOOL)deleteTable4Clazz:(Class<JRPersistent>)clazz inDB:(FMDatabase *)db;

- (void)registerClazz:(Class<JRPersistent>)clazz;

@end
