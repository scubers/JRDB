//
//  JRDBMgr.m
//  JRDB
//
//  Created by JMacMini on 16/5/10.
//  Copyright © 2016年 Jrwong. All rights reserved.
//

#import "JRDBMgr.h"
#import "JRReflectUtil.h"
#import "JRSqlGenerator.h"
#import "FMDatabase+JRDB.h"
#import "NSObject+JRDB.h"
#import <objc/message.h>

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

+ (FMDatabase *)defaultDB {
    return [[self shareInstance] defaultDB];
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

- (void)registerClazzForUpdateTable:(Class<JRPersistent>)clazz {
    [_clazzArray addObject:clazz];
    [clazz.self jr_swizzleSetters4Clazz];
}

- (NSArray<Class> *)registedClazz {
    return _clazzArray;
}

- (void)updateDefaultDB {
    [self updateDB:[self defaultDB]];
}

- (void)updateDB:(FMDatabase *)db {
    for (Class clazz in _clazzArray) {
        BOOL flag = [db updateTable4Clazz:clazz];
        NSLog(@"update table: %@ %@", [clazz description], flag ? @"success" : @"failure");
    }
}

#pragma mark - lazy load

- (FMDatabase *)defaultDB {
    if (!_defaultDB) {
        _defaultDB = [FMDatabase databaseWithPath:[self defaultPath]];
        [_defaultDB open];
    }
    return _defaultDB;
}

- (void)setDefaultDB:(FMDatabase *)defaultDB {
    if (_defaultDB == defaultDB) {
        return;
    }
    [_defaultDB closeQueue];
    [_defaultDB close];
    _defaultDB = defaultDB;
}

- (NSString *)defaultPath {
    NSFileManager *mgr = [NSFileManager defaultManager];
    NSString *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).lastObject;
    path = [path stringByAppendingPathComponent:@"jrdb"];
    BOOL isDirectory;
    if (![mgr fileExistsAtPath:path isDirectory:&isDirectory] || !isDirectory) {
        [mgr createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    }
    path = [path stringByAppendingPathComponent:@"jrdb.sqlite"];
    return path;
}


@end
