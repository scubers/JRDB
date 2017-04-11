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

@interface JRDBMgr()
{
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
        _maxConnectionCount = 1;
    }
    return self;
}

#pragma mark - database operation

- (id<JRPersistentHandler>)getHandler {
    return [self getHandlerWithPath:self.defaultDatabasePath];
}

- (id<JRPersistentHandler>)getHandlerWithPath:(NSString *)path {
    @synchronized (self) {
        NSMutableArray<id<JRPersistentHandler>> *connections = self.handlers[path];
        if (!connections) {
            connections = [NSMutableArray arrayWithCapacity:1];
            _handlers[path] = connections;
        }
        if (connections.count < _maxConnectionCount) {
            id<JRPersistentHandler> db = [FMDatabase databaseWithPath:path];
            [connections addObject:db];
        }
        id<JRPersistentHandler> handler = connections[(int)arc4random_uniform((int)connections.count)];
        [handler jr_openSynchronized:YES];
        return handler;
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

- (void)setDebugMode:(BOOL)debugMode {
    _debugMode = debugMode;
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



