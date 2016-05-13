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

- (void)closeQueue {
    [[self transactionQueue] close];
    objc_setAssociatedObject(self, &queuekey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

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
        EXE_BLOCK(block, db);
    }];
}

- (void)inTransaction:(void (^)(FMDatabase *, BOOL *))block {
    [[self transactionQueue] inTransaction:^(FMDatabase *db, BOOL *rollback) {
        EXE_BLOCK(block, db, rollback);
    }];
}


- (BOOL)createTable4Clazz:(Class<JRPersistent>)clazz {
    NSString *tableName = [JRReflectUtil shortClazzName:clazz];
    if (![self tableExists:tableName]) {
        return [self executeUpdate:[JRSqlGenerator createTableSql4Clazz:clazz]];
    }
    return YES;
}

- (void)createTable4Clazz:(Class<JRPersistent>)clazz complete:(JRDBComplete)complete {
    [self inTransaction:^(FMDatabase *db, BOOL *rollBack) {
        BOOL flag = [db createTable4Clazz:clazz];
        *rollBack = !flag;
        EXE_BLOCK(complete, flag);
    }];
}

- (BOOL)truncateTable4Clazz:(Class<JRPersistent>)clazz {
    if ([self checkExistsTable4Clazz:clazz]) {
        [self executeUpdate:[JRSqlGenerator dropTableSql4Clazz:clazz]];
    }
    return [self createTable4Clazz:clazz];
}

- (void)truncateTable4Clazz:(Class<JRPersistent>)clazz complete:(JRDBComplete)complete {
    [self inTransaction:^(FMDatabase *db, BOOL *rollBack) {
        BOOL flag = [db truncateTable4Clazz:clazz];
        *rollBack = !flag;
        EXE_BLOCK(complete, flag);
    }];
}

- (BOOL)updateTable4Clazz:(Class<JRPersistent>)clazz {
    NSArray *sqls = [JRSqlGenerator updateTableSql4Clazz:clazz inDB:self];
    BOOL flag = YES;
    for (NSString *sql in sqls) {
        flag = [self executeUpdate:sql];
        if (!flag) {
            break;
        }
    }
    return flag;
}

- (void)updateTable4Clazz:(Class<JRPersistent>)clazz complete:(JRDBComplete)complete {
    [self inTransaction:^(FMDatabase *db, BOOL *rollBack) {
        BOOL flag = [db updateTable4Clazz:clazz];
        *rollBack = !flag;
        EXE_BLOCK(complete, flag);
    }];
}

- (BOOL)dropTable4Clazz:(Class<JRPersistent>)clazz {
    NSString *tableName = [JRReflectUtil shortClazzName:clazz];
    if ([self tableExists:tableName]) {
        return [self executeUpdate:[JRSqlGenerator deleteTableSql4Clazz:clazz]];
    }
    return YES;
}

- (void)dropTable4Clazz:(Class<JRPersistent>)clazz complete:(JRDBComplete)complete {
    [self inTransaction:^(FMDatabase *db, BOOL *rollBack) {
        BOOL flag = [db dropTable4Clazz:clazz];
        *rollBack = !flag;
        EXE_BLOCK(complete, flag);
    }];
}


- (BOOL)saveObj:(id<JRPersistent>)obj {
    NSAssert(obj.ID == nil, @"The to be saved should not hold a primary key");
    if (![self tableExists:[JRReflectUtil shortClazzName:[obj class]]]) {
        if (![self createTable4Clazz:[obj class]]) {
            NSAssert(NO, @"create table: %@ error", [JRReflectUtil shortClazzName:[obj class]]);
        }
    }
    NSArray *args;
    NSString *sql = [JRSqlGenerator sql4Insert:obj args:&args];
    [obj setID:uuid()];
    args = [@[obj.ID] arrayByAddingObjectsFromArray:args];
    
    return [self executeUpdate:sql withArgumentsInArray:args];
}

- (void)saveObj:(id<JRPersistent>)obj complete:(JRDBComplete)complete {
    [self inQueue:^(FMDatabase *db) {
        EXE_BLOCK(complete, [db saveObj:obj]);
    }];
}

- (BOOL)updateObj:(id<JRPersistent>)obj {
    return [self updateObj:obj columns:nil];
}

- (void)updateObj:(id<JRPersistent>)obj complete:(JRDBComplete)complete {
    [self inQueue:^(FMDatabase *db) {
        EXE_BLOCK(complete, [db updateObj:obj]);
    }];
}

- (BOOL)updateObj:(id<JRPersistent>)obj columns:(NSArray *)columns {
    NSAssert(obj.ID != nil, @"The obj to be updated could be held a primary key");
    NSArray *args;
    NSString *sql = [JRSqlGenerator sql4Update:obj columns:columns args:&args];
    args = [args arrayByAddingObject:obj.ID];
    return [self executeUpdate:sql withArgumentsInArray:args];
}

- (void)updateObj:(id<JRPersistent>)obj columns:(NSArray *)columns complete:(JRDBComplete)complete {
    [self inQueue:^(FMDatabase *db) {
        EXE_BLOCK(complete, [db updateObj:obj columns:columns]);
    }];
}

- (BOOL)deleteObj:(id<JRPersistent>)obj {
    NSAssert(obj.ID != nil, @"obj ID should not be nil");
    NSString *sql = [JRSqlGenerator sql4Delete:obj];
    return [self executeUpdate:sql withArgumentsInArray:@[obj.ID]];
}

- (void)deleteObj:(id<JRPersistent>)obj complete:(JRDBComplete)complete {
    [self inQueue:^(FMDatabase *db) {
        EXE_BLOCK(complete, [db deleteObj:obj]);
    }];
}

- (id<JRPersistent>)findByID:(NSString *)ID clazz:(Class<JRPersistent>)clazz {
    NSAssert(ID != nil, @"id should be nil");
    NSAssert([self checkExistsTable4Clazz:clazz], @"table %@ doesn't exists", clazz);
    
    NSString *sql = [JRSqlGenerator sql4GetByIdWithClazz:clazz];
    FMResultSet *ret = [self executeQuery:sql withArgumentsInArray:@[ID]];
    return [JRFMDBResultSetHandler handleResultSet:ret forClazz:clazz].firstObject;
}

- (NSArray *)findAll:(Class<JRPersistent>)clazz {
    return [self findAll:clazz orderBy:nil isDesc:NO];
}

- (NSArray *)findAll:(Class<JRPersistent>)clazz orderBy:(NSString *)orderby isDesc:(BOOL)isDesc {
    if (![self checkExistsTable4Clazz:clazz]) {
        NSLog(@"table %@ doesn't exists", clazz);
        return @[];
    }
    
    NSString *sql = [JRSqlGenerator sql4FindAll:clazz orderby:orderby isDesc:isDesc];
    FMResultSet *ret = [self executeQuery:sql];
    return [JRFMDBResultSetHandler handleResultSet:ret forClazz:clazz];
}

- (NSArray *)findByConditions:(NSArray<JRQueryCondition *> *)conditions clazz:(Class<JRPersistent>)clazz groupBy:(NSString *)groupBy orderBy:(NSString *)orderBy limit:(NSString *)limit isDesc:(BOOL)isDesc {
    if (![self checkExistsTable4Clazz:clazz]) {
        NSLog(@"table %@ doesn't exists", clazz);
        return @[];
    }
    NSArray *args = nil;
    NSString *sql = [JRSqlGenerator sql4FindByConditions:conditions clazz:clazz groupBy:groupBy orderBy:orderBy limit:limit isDesc:isDesc args:&args];
    FMResultSet *ret = [self executeQuery:sql withArgumentsInArray:args];
    return [JRFMDBResultSetHandler handleResultSet:ret forClazz:clazz];
}

- (NSArray *)findByConditions:(NSArray<JRQueryCondition *> *)conditions clazz:(Class<JRPersistent>)clazz isDesc:(BOOL)isDesc {
    return [self findByConditions:conditions clazz:clazz groupBy:nil orderBy:nil limit:nil isDesc:isDesc];
}

- (NSArray *)findByConditions:(NSArray<JRQueryCondition *> *)conditions clazz:(Class<JRPersistent>)clazz groupBy:(NSString *)groupBy isDesc:(BOOL)isDesc {
    return [self findByConditions:conditions clazz:clazz groupBy:groupBy orderBy:nil limit:nil isDesc:isDesc];
}
- (NSArray *)findByConditions:(NSArray<JRQueryCondition *> *)conditions clazz:(Class<JRPersistent>)clazz orderBy:(NSString *)orderBy isDesc:(BOOL)isDesc {
    return [self findByConditions:conditions clazz:clazz groupBy:nil orderBy:orderBy limit:nil isDesc:isDesc];
}
- (NSArray *)findByConditions:(NSArray<JRQueryCondition *> *)conditions clazz:(Class<JRPersistent>)clazz limit:(NSString *)limit isDesc:(BOOL)isDesc {
    return [self findByConditions:conditions clazz:clazz groupBy:nil orderBy:nil limit:limit isDesc:isDesc];
}


- (BOOL)checkExistsTable4Clazz:(Class<JRPersistent>)clazz {
    return [self tableExists:[JRReflectUtil shortClazzName:clazz]];
}

@end


