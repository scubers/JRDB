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
    [self swizzleSetters4Clazz:clazz];
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

- (void)swizzleSetters4Clazz:(Class<JRPersistent>)clazz {
    unsigned int outCount;
    
    
    Method *list = class_copyMethodList(clazz, &outCount);
    for (int i = 0; i < outCount; i++) {
        Method method = list[i];
        SEL setter = method_getName(method);
        NSString *methodName = [NSString stringWithUTF8String:sel_getName(setter)];
        if ([methodName hasPrefix:@"set"] && [methodName hasSuffix:@":"]) {
            const char *typeEncoding = method_getTypeEncoding(method);
            NSString *newMethodName = [NSString stringWithFormat:@"jr_%@", methodName];
            
            SEL sel = sel_registerName([newMethodName UTF8String]);
            IMP imp = [self swizzleImp4Selector:sel inClazz:clazz];
            BOOL ret = class_addMethod(clazz, sel, imp, typeEncoding);
            
            if (ret) {
                Method newMethod = class_getInstanceMethod(clazz, sel);
                method_exchangeImplementations(method, newMethod);
            }
        }
    }
}

- (IMP)swizzleImp4Selector:(SEL)selector inClazz:(Class)clazz {
    Method method = class_getInstanceMethod(clazz, selector);
    const char *typeEncoding = method_getTypeEncoding(method);
    
    IMP imp;
    
    imp = imp_implementationWithBlock(^(id target, int value){
        NSLog(@"new method ");
        NSLog(@"target: %@, value: %d ", target, value);
        NSInvocation *inv = [NSInvocation invocationWithMethodSignature:[NSMethodSignature signatureWithObjCTypes:typeEncoding]];
        inv.selector = selector;
        inv.target = target;
        [inv setArgument:&value atIndex:2];
        [inv invoke];
    });
    
    return imp;
}

@end
