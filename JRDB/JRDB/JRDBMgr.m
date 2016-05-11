//
//  JRDBMgr.m
//  JRDB
//
//  Created by JMacMini on 16/5/10.
//  Copyright © 2016年 Jrwong. All rights reserved.
//

#import "JRDBMgr.h"
#import "FMDB.h"
#import "JRReflectUtil.h"
#import "JRSqlGenerator.h"
#import "FMDatabase+JRDB.h"

@interface JRDBMgr()
{
    FMDatabase *_defaultDB;
    NSMutableArray *_clazzArray;
}

@end

@implementation JRDBMgr

static JRDBMgr *__shareInstance;
+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __shareInstance = [super allocWithZone:zone];
        __shareInstance->_clazzArray = [NSMutableArray array];
    });
    return __shareInstance;
}
+ (instancetype)shareInstance {
    return [[self alloc] init];
}

- (FMDatabase *)createDBWithPath:(NSString *)path {
    FMDatabase *db = [FMDatabase databaseWithPath:path];
    [db open];
    return db;
}

- (void)deleteDBWithPath:(NSString *)path {
    FMDatabase *db = [FMDatabase databaseWithPath:path];
    [db close];
    NSFileManager *mgr = [NSFileManager defaultManager];
    [mgr removeItemAtPath:path error:nil];
}

- (FMDatabase *)DBWithPath:(NSString *)path {
    FMDatabase *db = [FMDatabase databaseWithPath:path];
    [db open];
    return db;
}

- (void)registerClazzForUpdateTable:(Class<JRPersistent>)clazz {
    [_clazzArray addObject:clazz];
}

- (void)updateDefaultDB {
    for (Class clazz in _clazzArray) {
        [_defaultDB updateTable4Clazz:clazz];
    }
}

#pragma mark - lazy load

- (FMDatabase *)defaultDB {
    if (!_defaultDB) {
        NSString *path = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES).lastObject;
        path = [path stringByAppendingPathComponent:@"jrdb/jrdb.sqlite"];
        _defaultDB = [FMDatabase databaseWithPath:path];
        [_defaultDB open];
    }
    return _defaultDB;
}

@end
