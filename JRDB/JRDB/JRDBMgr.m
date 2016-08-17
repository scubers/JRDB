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
#import <UIKit/UIKit.h>
#import "JRMiddleTable.h"

static NSString * const jrdb_class_registered_key = @"jrdb_class_registered_key";

@interface JRDBMgr()
{
    FMDatabase *_defaultDB;
    NSMutableArray<Class<JRPersistent>> *_clazzArray;
}

@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMutableDictionary<NSString *, id<JRPersistent>> *> *recursiveCache;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMutableDictionary<NSString *, id<JRPersistent>> *> *unRecursiveCache;

@end

@implementation JRDBMgr

@synthesize queues = _queues;

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

+ (FMDatabase *)defaultDB {
    return [[self shareInstance] defaultDB];
}

- (FMDatabase *)createDBWithPath:(NSString *)path {
    return [self databaseWithPath:path];
}
- (FMDatabase *)databaseWithPath:(NSString *)path {
    FMDatabase *db = self.dbs[path];
    if (!db) {
        db = [FMDatabase databaseWithPath:path];
        if (db) {
            [self.dbs setObject:db forKey:path];
            [db open];
        }
    }
    return db;
}

- (void)deleteDatabaseWithPath:(NSString *)path {
    FMDatabase *db = self.dbs[path];
    if (db) {
        [db close];
        JRDBQueue *queue = [self queueWithPath:path];
        [queue close];
        [self.queues removeObjectForKey:path];
    }
    NSFileManager *mgr = [NSFileManager defaultManager];
    [mgr removeItemAtPath:path error:nil];
}
- (void)deleteDBWithPath:(NSString *)path {
    [self deleteDatabaseWithPath:path];
}

- (JRDBQueue *)queueWithPath:(NSString *)path {
    JRDBQueue *queue = self.queues[path];
    if (!queue) {
        queue = [JRDBQueue databaseQueueWithPath:path];
        if (queue) [self.queues setObject:queue forKey:path];
    }
    return queue;
}

#pragma mark - logic operation

- (void)registerClazz:(Class<JRPersistent> _Nonnull)clazz {
    if ([_clazzArray containsObject:clazz]) { return; }
    [_clazzArray addObject:clazz];
    [self _configureRegisteredClazz:clazz];
    objc_setAssociatedObject(clazz, &jrdb_class_registered_key, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
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
        BOOL flag = [db jr_updateTable4Clazz:clazz synchronized:YES complete:nil];
        NSLog(@"update table: %@ %@", [clazz description], flag ? @"success" : @"failure");
    }
}

- (BOOL)isValidClazz:(Class<JRPersistent>)clazz {
    return [objc_getAssociatedObject(clazz, &jrdb_class_registered_key) boolValue];
}

- (void)closeDatabase:(FMDatabase *)database {
    [self closeDatabaseWithPath:database.databasePath];
}

- (void)closeDatabaseWithPath:(NSString *)path {
    [self.dbs[path] close];
    [self.queues[path] close];
}

- (void)close {
    [self.dbs enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, FMDatabase * _Nonnull obj, BOOL * _Nonnull stop) {
        [self closeDatabaseWithPath:key];
    }];
}

#pragma mark - lazy load

- (FMDatabase *)defaultDB {
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
    [_defaultDB open];
}

- (NSMutableDictionary<NSString *,JRDBQueue *> *)queues {
    if (!_queues) {
        _queues = [NSMutableDictionary dictionary];
    }
    return _queues;
}

- (NSMutableDictionary<NSString *,FMDatabase *> *)dbs {
    if (!_dbs) {
        _dbs = [NSMutableDictionary dictionary];
    }
    return _dbs;
}

- (NSMutableDictionary<NSString *,NSMutableDictionary<NSString *,id<JRPersistent>> *> *)recursiveCache {
    if (!_recursiveCache) {
        _recursiveCache = [NSMutableDictionary dictionary];
    }
    return _recursiveCache;
}

- (NSMutableDictionary<NSString *,NSMutableDictionary<NSString *,id<JRPersistent>> *> *)unRecursiveCache {
    if (!_unRecursiveCache) {
        _unRecursiveCache = [NSMutableDictionary dictionary];
    }
    return _unRecursiveCache;
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

#pragma mark - cache

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

- (void)clearObjCaches {
    self.unRecursiveCache = nil;
    self.recursiveCache = nil;
}

- (NSMutableDictionary<NSString *,id<JRPersistent>> *)recursiveCacheForDBPath:(NSString *)dbpath {
    NSMutableDictionary *cache = self.recursiveCache[dbpath];
    if (!cache) {
        cache = [NSMutableDictionary dictionary];
        self.recursiveCache[dbpath] = cache;
    }
    return cache;
}

- (NSMutableDictionary<NSString *,id<JRPersistent>> *)unRecursiveCacheForDBPath:(NSString *)dbpath {
    NSMutableDictionary *cache = self.unRecursiveCache[dbpath];
    if (!cache) {
        cache = [NSMutableDictionary dictionary];
        self.unRecursiveCache[dbpath] = cache;
    }
    return cache;
}


@end
