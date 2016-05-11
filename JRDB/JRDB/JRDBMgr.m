//
//  JRDBMgr.m
//  JRDB
//
//  Created by JMacMini on 16/5/10.
//  Copyright © 2016年 Jrwong. All rights reserved.
//

#import "JRDBMgr.h"
#import <FMDB.h>
#import "JRReflectUtil.h"
#import "JRSqlGenerator.h"

@interface JRDBMgr()

@property (nonatomic, strong) NSMutableArray<Class<JRPersistent>> *registeredClazz;
@property (nonatomic, strong) NSMutableArray<FMDatabase *> *dbs;

@end

@implementation JRDBMgr

static JRDBMgr *__shareInstance;
+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __shareInstance = [super allocWithZone:zone];
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
    NSFileManager *mgr = [NSFileManager defaultManager];
    FMDatabase *db = [FMDatabase databaseWithPath:path];
    [db close];
    [mgr removeItemAtPath:path error:nil];
}

- (FMDatabase *)DBWithPath:(NSString *)path {
    FMDatabase *db = [FMDatabase databaseWithPath:path];
    [db open];
    return db;
}

#pragma mark - lazy load
- (NSMutableArray<Class<JRPersistent>> *)registeredClazz {
    if (!_registeredClazz) {
        _registeredClazz = [NSMutableArray array];
    }
    return _registeredClazz;
}
- (NSMutableArray<FMDatabase *> *)dbs {
    if (!_dbs) {
        _dbs = [NSMutableArray array];
    }
    return _dbs;
}


@end
