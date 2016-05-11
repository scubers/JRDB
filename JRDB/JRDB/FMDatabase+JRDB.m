//
//  FMDatabase+JRDB.m
//  JRDB
//
//  Created by JMacMini on 16/5/10.
//  Copyright © 2016年 Jrwong. All rights reserved.
//



#import "FMDatabase+JRDB.h"
#import <objc/runtime.h>
#import "JRSqlGenerator.h"
#import "JRReflectUtil.h"
#import "JRDBMgr.h"
#import "JRFMDBResultSetHandler.h"
static NSString *queuekey = @"queuekey";

NSString * uuid() {
    CFUUIDRef uuidObject = CFUUIDCreate(kCFAllocatorDefault);
    NSString *uuidStr = (NSString *)CFBridgingRelease(CFUUIDCreateString(kCFAllocatorDefault, uuidObject));
    CFRelease(uuidObject);
    return uuidStr;
}

@implementation FMDatabase (JRDB)

- (FMDatabaseQueue *)myQueue {
    FMDatabaseQueue *q = objc_getAssociatedObject(self, &queuekey);
    if (!q) {
        q = [FMDatabaseQueue databaseQueueWithPath:self.databasePath];
        objc_setAssociatedObject(self, &queuekey, q, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return q;
}


- (void)createTable4Clazz:(Class<JRPersistent>)clazz {
    NSString *tableName = [JRReflectUtil shortClazzName:clazz];
    if (![self tableExists:tableName]) {
        [self executeUpdate:[JRSqlGenerator createTableSql4Clazz:clazz]];
    }
}

- (void)updateTable4Clazz:(Class<JRPersistent>)clazz {
    NSString *sql = [JRSqlGenerator updateTableSql4Clazz:clazz inDB:self];
    if (sql.length) {
        [self executeUpdate:sql];
    }
}

- (void)deleteTable4Clazz:(Class<JRPersistent>)clazz {
    NSString *tableName = [JRReflectUtil shortClazzName:clazz];
    if ([self tableExists:tableName]) {
        [self executeUpdate:[JRSqlGenerator deleteTableSql4Clazz:clazz]];
    }
    
}


- (BOOL)saveObj:(id<JRPersistent>)obj {
    return [self saveObj:obj synchronized:NO];
}

- (BOOL)saveObj:(id<JRPersistent>)obj synchronized:(BOOL)synchronized {
    if (![self tableExists:[JRReflectUtil shortClazzName:[obj class]]]) {
        [self createTable4Clazz:[obj class]];
    }
    NSArray *args;
    NSString *sql = [JRSqlGenerator sql4Insert:obj args:&args];
    if (!obj.ID.length) {
        [obj setID:uuid()];
        args = [@[obj.ID] arrayByAddingObjectsFromArray:args];
    }
    return [self executeUpdate:sql withArgumentsInArray:args];
}

- (BOOL)updateObj:(id<JRPersistent>)obj {
    return [self updateObj:obj columns:nil];
}

- (BOOL)updateObj:(id<JRPersistent>)obj columns:(NSArray *)columns {
    return [self updateObj:obj columns:columns synchronized:NO];
}

- (BOOL)updateObj:(id<JRPersistent>)obj columns:(NSArray *)columns synchronized:(BOOL)synchronized {
    NSAssert(obj.ID != nil, @"obj ID should not be nil");
    NSArray *args;
    NSString *sql = [JRSqlGenerator sql4Update:obj columns:columns args:&args];
    args = [args arrayByAddingObject:obj.ID];
    return [self executeUpdate:sql withArgumentsInArray:args];
}

- (BOOL)deleteObj:(id<JRPersistent>)obj {
    return [self deleteObj:obj synchronized:NO];
}

- (BOOL)deleteObj:(id<JRPersistent>)obj synchronized:(BOOL)synchronized {
    NSAssert(obj.ID != nil, @"obj ID should not be nil");
    NSString *sql = [JRSqlGenerator sql4Delete:obj];
    return [self executeUpdate:sql withArgumentsInArray:@[obj.ID]];
}

- (id<JRPersistent>)getByID:(NSString *)ID clazz:(Class<JRPersistent>)clazz {
    return [self getByID:ID clazz:clazz synchronized:clazz];
}

- (id<JRPersistent>)getByID:(NSString *)ID clazz:(Class<JRPersistent>)clazz synchronized:(BOOL)synchronized {
    NSAssert(ID != nil, @"id should be nil");
    NSString *sql = [JRSqlGenerator sql4GetByIdWithClazz:clazz];
    FMResultSet *ret = [self executeQuery:sql withArgumentsInArray:@[ID]];
    return [JRFMDBResultSetHandler handleResultSet:ret forClazz:clazz].firstObject;
}

- (NSArray *)findAll:(Class<JRPersistent>)clazz {
    return [self findAll:clazz synchronized:NO];
}

- (NSArray *)findAll:(Class<JRPersistent>)clazz synchronized:(BOOL)synchronized {
    NSString *sql = [JRSqlGenerator sql4FindAll:clazz];
    FMResultSet *ret = [self executeQuery:sql];
    return [JRFMDBResultSetHandler handleResultSet:ret forClazz:clazz];
}

@end


