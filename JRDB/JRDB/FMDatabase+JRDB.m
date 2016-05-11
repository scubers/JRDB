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
#import "JRQueryCondition.h"
static NSString *queuekey = @"queuekey";

NSString * uuid() {
    CFUUIDRef uuidObject = CFUUIDCreate(kCFAllocatorDefault);
    NSString *uuidStr = (NSString *)CFBridgingRelease(CFUUIDCreateString(kCFAllocatorDefault, uuidObject));
    CFRelease(uuidObject);
    return uuidStr;
}

@implementation FMDatabase (JRDB)

- (FMDatabaseQueue *)transactionQueue {
    FMDatabaseQueue *q = objc_getAssociatedObject(self, &queuekey);
    if (!q) {
        q = [FMDatabaseQueue databaseQueueWithPath:self.databasePath];
        objc_setAssociatedObject(self, &queuekey, q, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return q;
}

- (void)inQueue:(void (^)(FMDatabase *))block {
    [[self transactionQueue] inDatabase:^(FMDatabase *db) {
        if (block) {
            block(db);
        }
    }];
}

- (void)inTransaction:(void (^)(FMDatabase *, BOOL *))block {
    [[self transactionQueue] inTransaction:^(FMDatabase *db, BOOL *rollback) {
        if (block) {
            block(db, rollback);
        }
    }];
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
    NSAssert(obj.ID != nil, @"obj ID should not be nil");
    NSArray *args;
    NSString *sql = [JRSqlGenerator sql4Update:obj columns:columns args:&args];
    args = [args arrayByAddingObject:obj.ID];
    return [self executeUpdate:sql withArgumentsInArray:args];
}

- (BOOL)deleteObj:(id<JRPersistent>)obj {
    NSAssert(obj.ID != nil, @"obj ID should not be nil");
    NSString *sql = [JRSqlGenerator sql4Delete:obj];
    return [self executeUpdate:sql withArgumentsInArray:@[obj.ID]];
}

- (id<JRPersistent>)getByID:(NSString *)ID clazz:(Class<JRPersistent>)clazz {
    NSAssert(ID != nil, @"id should be nil");
    NSString *sql = [JRSqlGenerator sql4GetByIdWithClazz:clazz];
    FMResultSet *ret = [self executeQuery:sql withArgumentsInArray:@[ID]];
    return [JRFMDBResultSetHandler handleResultSet:ret forClazz:clazz].firstObject;
}

- (NSArray *)findAll:(Class<JRPersistent>)clazz {
    return [self findAll:clazz orderBy:nil isDesc:NO];
}

- (NSArray *)findAll:(Class<JRPersistent>)clazz orderBy:(NSString *)orderby isDesc:(BOOL)isDesc {
    NSString *sql = [JRSqlGenerator sql4FindAll:clazz orderby:orderby isDesc:isDesc];
    FMResultSet *ret = [self executeQuery:sql];
    return [JRFMDBResultSetHandler handleResultSet:ret forClazz:clazz];
}

- (NSArray *)findByConditions:(NSArray<JRQueryCondition *> *)conditions clazz:(Class<JRPersistent>)clazz isDesc:(BOOL)isDesc {
    NSString *sql = [JRSqlGenerator sql4FindByConditions:conditions clazz:clazz isDesc:isDesc];
    FMResultSet *ret = [self executeQuery:sql];
    return [JRFMDBResultSetHandler handleResultSet:ret forClazz:clazz];
}

@end


