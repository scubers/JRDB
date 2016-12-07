//
//  JRDBMgr.m
//  JRDB
//
//  Created by JMacMini on 16/5/10.
//  Copyright © 2016年 Jrwong. All rights reserved.
//

#import "JRDBMgr.h"
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
/** 对应的数据库路径，和所管理的连接数 */
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMutableArray<id<JRPersistentHandler>> *> *handlers;

@end

@implementation JRDBMgr

#pragma mark - life

static JRDBMgr *__shareInstance;

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __shareInstance = [super allocWithZone:zone];
    });
    return __shareInstance;
}

+ (instancetype)shareInstance {
    if (__shareInstance) return __shareInstance;
    return [[self alloc] init];
}

- (instancetype)init {
    if (self = [super init]) {
        _clazzArray = [NSMutableArray arrayWithCapacity:1];
        _maxConnectionCount = 5;
#ifdef DEBUG
        _debugMode = YES;
#endif
    }
    return self;
}

#pragma mark - database operation

- (id<JRPersistentHandler>)getHandler {
    @synchronized (self) {
        NSString *path = self.defaultDatabasePath;
        NSMutableArray<id<JRPersistentHandler>> *connections = self.handlers[path];
        if (!connections) {
            connections = [NSMutableArray arrayWithCapacity:1];
            _handlers[path] = connections;
        }
        
        if (connections.count < _maxConnectionCount) {
            FMDatabase *db = [FMDatabase databaseWithPath:path];
            [db open];
            [connections addObject:db];
        }
        return connections[(int)arc4random_uniform((int)_handlers.count)];
    }
}

- (void)deleteDatabaseWithPath:(NSString *)path {
    [self.handlers[path] enumerateObjectsUsingBlock:^(id<JRPersistentHandler>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj jr_closeSynchronized:YES];
    }];
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

- (void)closeDatabaseWithPath:(NSString *)path {
    [self.handlers[path] enumerateObjectsUsingBlock:^(id<JRPersistentHandler>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj jr_closeSynchronized:YES];
    }];
}

- (void)close {
    [self.handlers enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSMutableArray<id<JRPersistentHandler>> * _Nonnull obj, BOOL * _Nonnull stop) {
       [obj enumerateObjectsUsingBlock:^(id<JRPersistentHandler>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
           [obj jr_closeSynchronized:YES];
       }];
    }];
}

#pragma mark - lazy load

@synthesize defaultDatabasePath = _defaultDatabasePath;

- (NSString *)defaultDatabasePath {
    if (!_defaultDatabasePath) {
        _defaultDatabasePath = [self _defaultPath];
    }
    return _defaultDatabasePath;
}

- (void)setDefaultDatabasePath:(NSString *)defaultDatabasePath {
    NSString *oldPath = _defaultDatabasePath;
    _defaultDatabasePath = [defaultDatabasePath copy];
    [self closeDatabaseWithPath:oldPath];
}

- (NSMutableDictionary<NSString *, NSMutableArray<id<JRPersistentHandler>> *> *)handlers {
    if (!_handlers) {
        _handlers = [[NSMutableDictionary<NSString *, NSMutableArray<id<JRPersistentHandler>> *> alloc] init];
    }
    return _handlers;
}


#pragma mark - private method

- (void)clearMidTableRubbishDataForDB:(id<JRPersistentHandler>)db {
    
    [_clazzArray enumerateObjectsUsingBlock:^(Class<JRPersistent>  _Nonnull clazz, NSUInteger idx, BOOL * _Nonnull stop) {
        
        if (idx == _clazzArray.count - 1) { return ; }
        
        for (NSUInteger i = idx + 1; i < _clazzArray.count; i++) {
            JRMiddleTable *mid = [JRMiddleTable table4Clazz:clazz andClazz:_clazzArray[i] db:((FMDatabase *)db)];
            if ([((FMDatabase *)db) tableExists:[mid tableName]]) {
                [mid cleanRubbishData];
            }
        }
    }];
}

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



