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
#import "FMDatabase+JRPersistentHandler.h"
#import "NSObject+JRDB.h"
#import <objc/message.h>
#import <UIKit/UIKit.h>
#import "JRMiddleTable.h"

static NSString * const jrdb_class_registered_key = @"jrdb_class_registered_key";

@interface JRDBMgr()
{
    id<JRPersistentHandler> _defaultDB;
    NSMutableArray<Class<JRPersistent>> *_clazzArray;
}


@end

@implementation JRDBMgr

@synthesize dbs = _dbs;

#pragma mark - life

static JRDBMgr *__shareInstance;

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        __shareInstance = [super allocWithZone:zone];
        __shareInstance->_clazzArray = [NSMutableArray array];
        
        [[NSNotificationCenter defaultCenter] addObserver:__shareInstance selector:@selector(clearObjCaches) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
#ifdef DEBUG
        __shareInstance->_debugMode = YES;
#endif
    });
    return __shareInstance;
}

+ (instancetype)shareInstance {
    return [[self alloc] init];
}

#pragma mark - database operation

+ (id<JRPersistentHandler>)defaultDB {
    return [[self shareInstance] defaultDB];
}

- (id<JRPersistentHandler>)databaseWithPath:(NSString *)path {
    id<JRPersistentHandler> db = self.dbs[path];
    if (!db) {
        db = [FMDatabase databaseWithPath:path];
        if (db) {
            [self.dbs setObject:db forKey:path];
            [db jr_openSynchronized:YES];
        }
    }
    return db;
}

- (void)deleteDatabaseWithPath:(NSString *)path {
    id<JRPersistentHandler> db = self.dbs[path];
    if (db) {
        [db jr_closeSynchronized:YES];
    }
    NSFileManager *mgr = [NSFileManager defaultManager];
    [mgr removeItemAtPath:path error:nil];
}

#pragma mark - logic operation

- (void)registerClazz:(Class<JRPersistent> _Nonnull)clazz {
    if ([_clazzArray containsObject:clazz]) { return; }
    [_clazzArray addObject:clazz];
    [self _configureRegisteredClazz:clazz];
    [clazz setRegistered:YES];
}

- (void)registerClazzes:(NSArray<Class<JRPersistent>> *)clazzArray {
    [clazzArray enumerateObjectsUsingBlock:^(Class<JRPersistent>  _Nonnull clazz, NSUInteger idx, BOOL * _Nonnull stop) {
        [self registerClazz:clazz];
    }];
}

- (NSArray<Class> *)registeredClazz {
    return _clazzArray;
}

- (void)closeDatabase:(id<JRPersistentHandler>)database {
    [self closeDatabaseWithPath:database.handlerIdentifier];
}

- (void)closeDatabaseWithPath:(NSString *)path {
    [self.dbs[path] jr_closeSynchronized:YES];
}

- (void)close {
    [self.dbs enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, id<JRPersistentHandler> _Nonnull obj, BOOL * _Nonnull stop) {
        [self closeDatabase:obj];
    }];
}

#pragma mark - lazy load

- (id<JRPersistentHandler>)defaultDB {
    if (!_defaultDB) {
        _defaultDB = [self databaseWithPath:[self _defaultPath]];
    }
    return _defaultDB;
}

- (void)setDefaultDB:(FMDatabase *)defaultDB {
    if (_defaultDB == defaultDB) {
        return;
    }
    [self closeDatabase:_defaultDB];
    _defaultDB = defaultDB;
    [_defaultDB jr_openSynchronized:YES];
}

- (NSMutableDictionary<NSString *,id<JRPersistentHandler>> *)dbs {
    if (!_dbs) {
        _dbs = [NSMutableDictionary dictionary];
    }
    return _dbs;
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

#pragma mark - Cache DEPRECATED


@implementation JRDBMgr (DEPRECATED)

@dynamic queues;
@dynamic unRecursiveCache;
@dynamic recursiveCache;

- (void)clearObjCaches {
    self.unRecursiveCache = nil;
    self.recursiveCache = nil;
}

- (NSMutableDictionary<NSString *,id<JRPersistent>> *)recursiveCacheForDBPath:(NSString *)dbpath {
    return nil;
}

- (NSMutableDictionary<NSString *,id<JRPersistent>> *)unRecursiveCacheForDBPath:(NSString *)dbpath {
    return nil;
}

- (JRDBQueue *)queueWithPath:(NSString *)path {
    return nil;
}

- (void)updateDefaultDB {}

- (void)updateDB:(FMDatabase *)db {}

- (id<JRPersistentHandler>)createDBWithPath:(NSString *)path {
    return [self databaseWithPath:path];
}

- (void)deleteDBWithPath:(NSString *)path {
    [self deleteDatabaseWithPath:path];
}





@end
