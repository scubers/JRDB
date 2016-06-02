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
#import "NSObject+JRDB.h"

static NSString * const queuekey = @"queuekey";

NSString * uuid() {
    CFUUIDRef uuidObject = CFUUIDCreate(kCFAllocatorDefault);
    NSString *uuidStr = (NSString *)CFBridgingRelease(CFUUIDCreateString(kCFAllocatorDefault, uuidObject));
    CFRelease(uuidObject);
    return uuidStr;
}

@implementation FMDatabase (JRDB)

#pragma mark - queue action
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

#pragma mark - table operation

- (BOOL)createTable4Clazz:(Class<JRPersistent>)clazz {
    if (![self checkExistsTable4Clazz:clazz]) {
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
    if ([self checkExistsTable4Clazz:clazz]) {
        return [self executeUpdate:[JRSqlGenerator dropTableSql4Clazz:clazz]];
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

#pragma mark - data operation

- (BOOL)saveObj:(id<JRPersistent>)obj {
    
    NSString *tableName = [JRReflectUtil shortClazzName:[obj class]];
    if (![self tableExists:tableName]) {
        NSAssert([self createTable4Clazz:[obj class]], @"create table: %@ error", tableName);
    }
    
    if ([[obj class] jr_customPrimarykey]) { // 自定义主键
        NSAssert([obj jr_customPrimarykeyValue] != nil, @"custom Primary key should not be nil");
        NSObject *old = [[obj class] jr_findByPrimaryKey:[obj jr_customPrimarykeyValue]];
        NSAssert(!old, @"primary key is exists");
    } else { // 默认主键
        NSAssert(obj.ID == nil, @"The to be saved should not hold a primary key");
    }
    
    
    NSArray *args;
    NSString *sql = [JRSqlGenerator sql4Insert:obj args:&args toDB:self];
    [obj setID:uuid()];
    args = [@[obj.ID] arrayByAddingObjectsFromArray:args];
    
    BOOL ret = [self executeUpdate:sql withArgumentsInArray:args];
    
    return ret;
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
    NSAssert([obj jr_primaryKeyValue], @"The obj to be updated should hold a primary key");
    
    // 表不存在
    if (![self checkExistsTable4Clazz:[obj class]]) {
        NSLog(@"table : %@ doesn't exists", [obj class]);
        return NO;
    }
    
    id<JRPersistent> updateObj;
    if (columns.count) {
        id<JRPersistent> old = [self findByPrimaryKey:[obj jr_primaryKeyValue] clazz:[obj class]];
        if (!old) {
            NSLog(@"The object doesn't exists in database");
            return NO;
        }
        for (NSString *name in columns) {
            id value = [((NSObject *)obj) valueForKey:name];
            [((NSObject *)old) setValue:value forKey:name];
        }
        updateObj = old;
    } else {
        updateObj = obj;
    }
    
    NSArray *args;
    NSString *sql = [JRSqlGenerator sql4Update:updateObj columns:columns args:&args toDB:self];
    args = [args arrayByAddingObject:[updateObj jr_primaryKeyValue]];

    BOOL ret = [self executeUpdate:sql withArgumentsInArray:args];
    return ret;
}

- (void)updateObj:(id<JRPersistent>)obj columns:(NSArray *)columns complete:(JRDBComplete)complete {
    [self inQueue:^(FMDatabase *db) {
        EXE_BLOCK(complete, [db updateObj:obj columns:columns]);
    }];
}

- (BOOL)deleteObj:(id<JRPersistent>)obj {
    NSAssert([obj jr_primaryKeyValue], @"primary key should not be nil");
    
    if (![self checkExistsTable4Clazz:[obj class]]) {
        NSLog(@"table : %@ doesn't exists", [obj class]);
        return NO;
    }
    
    NSString *sql = [JRSqlGenerator sql4Delete:obj];
    return [self executeUpdate:sql withArgumentsInArray:@[[obj jr_primaryKeyValue]]];
}

- (void)deleteObj:(id<JRPersistent>)obj complete:(JRDBComplete)complete {
    [self inQueue:^(FMDatabase *db) {
        EXE_BLOCK(complete, [db deleteObj:obj]);
    }];
}

#pragma mark - query operation

- (id<JRPersistent>)findByPrimaryKey:(id)ID clazz:(Class<JRPersistent>)clazz {
    
    NSAssert(ID, @"id should be nil");
    NSAssert([self checkExistsTable4Clazz:clazz], @"table %@ doesn't exists", clazz);
    
    NSString *sql = [JRSqlGenerator sql4GetByPrimaryKeyWithClazz:clazz];
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

#pragma mark - private
- (BOOL)checkExistsTable4Clazz:(Class<JRPersistent>)clazz {
    return [self tableExists:[JRReflectUtil shortClazzName:clazz]];
}

@end


