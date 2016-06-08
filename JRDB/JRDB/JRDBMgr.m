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
#import "JRMiddleTable.h"

@interface JRDBMgr()
{
    FMDatabase *_defaultDB;
    NSMutableArray<Class<JRPersistent>> *_clazzArray;
}

@end

@implementation JRDBMgr

static JRDBMgr *__shareInstance;
+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __shareInstance = [super allocWithZone:zone];
        __shareInstance->_clazzArray = [NSMutableArray array];
#ifdef DEBUG
        __shareInstance->_debugMode = YES;
#else
        __shareInstance->_debugMode = NO;
#endif
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

- (void)registerClazz:(Class<JRPersistent> _Nonnull)clazz {
    if ([_clazzArray containsObject:clazz]) { return; }
    [_clazzArray addObject:clazz];
    [self _configureRegisteredClazz:clazz];
}

- (void)registerClazzes:(NSArray<Class<JRPersistent>> *)clazzArray {
    [clazzArray enumerateObjectsUsingBlock:^(Class<JRPersistent>  _Nonnull clazz, NSUInteger idx, BOOL * _Nonnull stop) {
        [self registerClazz:clazz];
    }];
}

- (NSArray<Class> *)registeredClazz {
    return _clazzArray;
}

- (void)updateDefaultDB {
    [self updateDB:[self defaultDB]];
}

- (void)updateDB:(FMDatabase *)db {
    for (Class clazz in _clazzArray) {
        BOOL flag = [db jr_updateTable4Clazz:clazz];
        NSLog(@"update table: %@ %@", [clazz description], flag ? @"success" : @"failure");
    }
}

- (BOOL)isValidateClazz:(Class<JRPersistent>)clazz {
//    return [_clazzArray containsObject:clazz]; //为什么在cocoapods会报错，其他就不会，神经病 艹
    for (Class c in _clazzArray) {
        if ([NSStringFromClass(c) isEqualToString:NSStringFromClass(clazz)]) {
            return YES;
        }
    }
    return NO;
}

- (void)clearMidTableRubbishDataForDB:(FMDatabase *)db {

    [_clazzArray enumerateObjectsUsingBlock:^(Class<JRPersistent>  _Nonnull clazz, NSUInteger idx, BOOL * _Nonnull stop) {
        
        if (idx == _clazzArray.count - 1) { return ; }
        
        for (NSUInteger i = idx + 1; i < _clazzArray.count; i++) {
            JRMiddleTable *mid = [JRMiddleTable table4Clazz:clazz andClazz:_clazzArray[i] db:db];
            if ([db tableExists:[mid tableName]]) {
                [mid cleanRubbishData];
            }
        }
    }];
}

#pragma mark - lazy load

- (FMDatabase *)defaultDB {
    if (!_defaultDB) {
        _defaultDB = [FMDatabase databaseWithPath:[self _defaultPath]];
        [_defaultDB open];
    }
    return _defaultDB;
}

- (void)setDefaultDB:(FMDatabase *)defaultDB {
    if (_defaultDB == defaultDB) {
        return;
    }
    [_defaultDB jr_closeQueue];
    [_defaultDB close];
    
    _defaultDB = defaultDB;
    [_defaultDB open];
}

#pragma mark - private method

- (NSString *)_defaultPath {
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

- (void)_configureRegisteredClazz:(Class)clazz {
    [clazz jr_configure];
}

@end
