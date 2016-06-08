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
#import "JRUtils.h"
#import "JRMiddleTable.h"


#define AssertRegisteredClazz(clazz) NSAssert([[JRDBMgr shareInstance] isValidateClazz:clazz], @"class: %@ should be registered in JRDBMgr", clazz)

static NSString * const queuekey = @"queuekey";

@implementation FMDatabase (JRDB)

#pragma mark - queue action
- (void)jr_closeQueue {
    [[self jr_databaseQueue] close];
    objc_setAssociatedObject(self, &queuekey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (FMDatabaseQueue *)jr_databaseQueue {
    FMDatabaseQueue *q = objc_getAssociatedObject(self, &queuekey);
    if (!q) {
        q = [FMDatabaseQueue databaseQueueWithPath:self.databasePath];
        objc_setAssociatedObject(self, &queuekey, q, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return q;
}

- (void)jr_inQueue:(void (^)(FMDatabase *))block {
    [[self jr_databaseQueue] inDatabase:^(FMDatabase *db) {
        EXE_BLOCK(block, db);
    }];
}

- (BOOL)jr_inTransaction:(void (^)(FMDatabase *, BOOL *))block {
    BOOL flag = [self beginTransaction];
    if (!flag) {
        NSLog(@"begin transaction fail");
        return NO;
    }
    BOOL rollback = NO;
    EXE_BLOCK(block, self, &rollback);
    if (rollback) {
        [self rollback];
        return NO;
    } else {
        return [self commit];
    }
}

- (BOOL)jr_execute:(BOOL (^)(FMDatabase * _Nonnull db))block useTransaction:(BOOL)useTransaction {
    if (useTransaction) {
        NSAssert(![self inTransaction], @"database has been open a transaction");
        if (![self beginTransaction]) {
            NSLog(@"begin a transaction error!!!");
            return NO;
        }
    }
    BOOL flag = block(self);
    if (useTransaction) {
        flag ? [self commit] : [self rollback];
    }
    return flag;
}

#pragma mark - table operation

- (BOOL)jr_createTable4Clazz:(Class<JRPersistent>)clazz {
    
    AssertRegisteredClazz(clazz);
    
    if (![self jr_checkExistsTable4Clazz:clazz]) {
        return [self executeUpdate:[JRSqlGenerator createTableSql4Clazz:clazz]];
    }
    return YES;
}

- (void)jr_createTable4Clazz:(Class<JRPersistent>)clazz complete:(JRDBComplete)complete {
    [self jr_inTransaction:^(FMDatabase *db, BOOL *rollBack) {
        BOOL flag = [db jr_createTable4Clazz:clazz];
        *rollBack = !flag;
        EXE_BLOCK(complete, flag);
    }];
}

- (BOOL)jr_truncateTable4Clazz:(Class<JRPersistent>)clazz {
    AssertRegisteredClazz(clazz);
    if ([self jr_checkExistsTable4Clazz:clazz]) {
        [self executeUpdate:[JRSqlGenerator dropTableSql4Clazz:clazz]];
    }
    return [self jr_createTable4Clazz:clazz];
}

- (void)jr_truncateTable4Clazz:(Class<JRPersistent>)clazz complete:(JRDBComplete)complete {
    [self jr_inTransaction:^(FMDatabase *db, BOOL *rollBack) {
        BOOL flag = [db jr_truncateTable4Clazz:clazz];
        *rollBack = !flag;
        EXE_BLOCK(complete, flag);
    }];
}

- (BOOL)jr_updateTable4Clazz:(Class<JRPersistent>)clazz {
    AssertRegisteredClazz(clazz);
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

- (void)jr_updateTable4Clazz:(Class<JRPersistent>)clazz complete:(JRDBComplete)complete {
    [self jr_inTransaction:^(FMDatabase *db, BOOL *rollBack) {
        BOOL flag = [db jr_updateTable4Clazz:clazz];
        *rollBack = !flag;
        EXE_BLOCK(complete, flag);
    }];
}

- (BOOL)jr_dropTable4Clazz:(Class<JRPersistent>)clazz {
    AssertRegisteredClazz(clazz);
    if ([self jr_checkExistsTable4Clazz:clazz]) {
        return [self executeUpdate:[JRSqlGenerator dropTableSql4Clazz:clazz]];
    }
    return YES;
}

- (void)jr_dropTable4Clazz:(Class<JRPersistent>)clazz complete:(JRDBComplete)complete {
    [self jr_inTransaction:^(FMDatabase *db, BOOL *rollBack) {
        BOOL flag = [db jr_dropTable4Clazz:clazz];
        *rollBack = !flag;
        EXE_BLOCK(complete, flag);
    }];
}

#pragma mark - table message

- (NSArray<JRColumnSchema *> *)jr_schemasInClazz:(Class<JRPersistent>)clazz {
    AssertRegisteredClazz(clazz);
    FMResultSet *ret = [[JRDBMgr defaultDB] getTableSchema:[clazz shortClazzName]];
//    get table schema: result colums: cid[INTEGER], name,type [STRING], notnull[INTEGER], dflt_value[],pk[INTEGER]
    NSMutableArray *schemas = [NSMutableArray array];
    while ([ret next]) {
        JRColumnSchema *schema = [JRColumnSchema new];
        schema.cid = [ret intForColumn:@"cid"];
        schema.name = [ret stringForColumn:@"name"];
        schema.type = [ret stringForColumn:@"type"];
        schema.notnull = [ret intForColumn:@"notnull"];
        schema.pk = [ret intForColumn:@"pk"];
        [schemas addObject:schema];
    }
    return schemas;
}

#pragma mark - link operation

- (BOOL)jr_handleSave:(id<JRPersistent>)obj stack:(NSMutableArray<id<JRPersistent>> **)stack needRollBack:(BOOL *)needRollBack {
    
    if (*needRollBack) {
        return NO;
    }
    
    [[[obj class] jr_singleLinkedPropertyNames] enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, Class<JRPersistent>  _Nonnull clazz, BOOL * _Nonnull stop) {
        id value = [((NSObject *)obj) valueForKey:key];
        if (value) {
            NSString *identifier = [JRUtils uuid];
            if ([*stack containsObject:value]) {
                [value jr_addDidFinishBlock:^(id<JRPersistent>  _Nonnull object) {
                    [object jr_removeDidFinishBlockForIdentifier:identifier];
                    [self jr_updateOne:obj columns:nil useTransaction:NO];
                } forIdentifier:identifier];
            } else {
                if (![*stack containsObject:obj]) {
                    [*stack addObject:obj];
                }
                [obj jr_addDidFinishBlock:^(id<JRPersistent>  _Nonnull object) {
                    [object jr_removeDidFinishBlockForIdentifier:identifier];
                    [*stack removeObject:object];
                } forIdentifier:identifier];
                [self jr_handleSave:value stack:stack needRollBack:needRollBack];
            }
        }
    }];
    
    NSString *tableName = [[obj class] shortClazzName];
    if (![self tableExists:tableName]) {
        if(![self jr_createTable4Clazz:[obj class]]) {
            NSLog(@"create table: %@ error", tableName);
            *needRollBack = YES;
            return NO;
        }
    }


    id<JRPersistent> old;
    if ([obj jr_primaryKeyValue]) {
        old = [self jr_getByPrimaryKey:[obj jr_primaryKeyValue] clazz:[obj class]];
    }

    if (!old) {
        BOOL ret = [self jr_saveOneOnly:obj];
        *needRollBack = !ret;
        if (!ret) {
            NSLog(@"save obj: %@ error, transaction will be rollback", obj);
        }
        return ret;
    } else {
        NSLog(@"obj for primary key : %@ ,has been exisist, can not be saved", [old jr_primaryKeyValue]);
        [obj setID:[old ID]];
        // 子对象已经存在不用保存，直接返回，若需要更新，需要自行手动更新
        return YES;
    }
    
}

- (BOOL)jr_handleOneToManySaveWithObj:(id<JRPersistent>)obj columns:(NSArray *)columns {
    NSAssert([self inTransaction], @"should in transaction");
    
    __block BOOL needRollBack = NO;
    // 监测一对多的保存
    [[[obj class] jr_oneToManyLinkedPropertyNames] enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, Class<JRPersistent>  _Nonnull clazz, BOOL * _Nonnull stop) {
        
        if (!columns || [columns containsObject:key]) {
            NSArray *array = [((NSObject *)obj) valueForKey:key];
            // 逐个保存
            [array enumerateObjectsUsingBlock:^(NSObject<JRPersistent> * _Nonnull subObj, NSUInteger idx, BOOL * _Nonnull stop) {
                if (![subObj jr_primaryKeyValue]) {
                    needRollBack = ![self jr_saveOne:subObj useTransaction:NO];
                    *stop = needRollBack;
                }
            }];
            // 保存中建表
            JRMiddleTable *mid = [JRMiddleTable table4Clazz:clazz andClazz:[obj class] db:self];
            needRollBack = ![mid saveObjs:array forObj:obj];
            *stop = needRollBack;
        }
        
    }];
    return !needRollBack;
}

#pragma mark - save or update

- (BOOL)jr_saveOrUpdateOneOnly:(id<JRPersistent> _Nonnull)one {
    return NO;
}

#pragma mark - save one

/**
 *  保存单条，不关联保存
 */
- (BOOL)jr_saveOneOnly:(id<JRPersistent>)one {
    AssertRegisteredClazz([one class]);
    if ([[one class] jr_customPrimarykey]) { // 自定义主键
        NSAssert([one jr_customPrimarykeyValue] != nil, @"custom Primary key should not be nil");
        NSObject *old = (NSObject *)[self jr_getByPrimaryKey:[one jr_customPrimarykeyValue] clazz:[one class]];
        NSAssert(!old, @"primary key is exists");
    } else { // 默认主键
        NSAssert(one.ID == nil, @"The obj:%@ to be saved should not hold a primary key", one);
    }
    
    NSArray *args;
    NSString *sql = [JRSqlGenerator sql4Insert:one args:&args toDB:self];
    [one setID:[JRUtils uuid]];
    args = [@[one.ID] arrayByAddingObjectsFromArray:args];
    BOOL ret = [self executeUpdate:sql withArgumentsInArray:args];
    
    if (ret) {
        // 保存完，执行block
        [one jr_executeFinishBlocks];
    }
    return ret;
}

- (BOOL)jr_saveOne:(id<JRPersistent>)one useTransaction:(BOOL)useTransaction {
    AssertRegisteredClazz([one class]);
    
    return
    
    [self jr_execute:^BOOL(FMDatabase * _Nonnull db) {
        
        NSMutableArray *stack = [NSMutableArray array];
        __block BOOL needRollBack = NO;
        [db jr_handleSave:one stack:&stack needRollBack:&needRollBack];
        
        if (!needRollBack) {
            // 监测一对多的保存
            needRollBack = ![db jr_handleOneToManySaveWithObj:one columns:nil];
        }
        return !needRollBack;
        
    } useTransaction:useTransaction];
    
}

- (void)jr_saveOne:(id<JRPersistent>)one useTransaction:(BOOL)useTransaction complete:(JRDBComplete)complete {
    [self jr_inQueue:^(FMDatabase * _Nonnull db) {
        BOOL flag = [db jr_saveOne:one useTransaction:useTransaction];
        EXE_BLOCK(complete, flag);
    }];
}

- (BOOL)jr_saveOne:(id<JRPersistent>)one {
    return [self jr_saveOne:one useTransaction:YES];
}

- (void)jr_saveOne:(id<JRPersistent>)one complete:(JRDBComplete)complete {
    [self jr_saveOne:one useTransaction:YES complete:complete];
}

#pragma mark - save array

- (BOOL)jr_saveObjects:(NSArray<id<JRPersistent>> *)objects useTransaction:(BOOL)useTransaction {
    return
    [self jr_execute:^BOOL(FMDatabase * _Nonnull db) {
        __block BOOL needRollBack = NO;
        [objects enumerateObjectsUsingBlock:^(id<JRPersistent>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            needRollBack = ![db jr_saveOne:obj useTransaction:NO];
            *stop = needRollBack;
        }];
        return !needRollBack;
    } useTransaction:useTransaction];
}

- (void)jr_saveObjects:(NSArray<id<JRPersistent>> *)objects useTransaction:(BOOL)useTransaction complete:(JRDBComplete)complete {
    [self jr_inQueue:^(FMDatabase * _Nonnull db) {
        BOOL flag = [db jr_saveObjects:objects useTransaction:useTransaction];
        EXE_BLOCK(complete, flag);
    }];
}

- (BOOL)jr_saveObjects:(NSArray<id<JRPersistent>> *)objects {
    return [self jr_saveObjects:objects useTransaction:YES];
}

- (void)jr_saveObjects:(NSArray<id<JRPersistent>> *)objects complete:(JRDBComplete)complete {
    [self jr_saveObjects:objects useTransaction:YES complete:complete];
}

#pragma mark - update

/**
 *  只更新数据，不进行关联操作
 *
 *  @param obj
 *  @param columns
 */
- (BOOL)jr_updateOneOnly:(id<JRPersistent>)one columns:(NSArray<NSString *> *)columns {
    
    AssertRegisteredClazz([one class]);
    
    NSAssert([one jr_primaryKeyValue], @"The obj to be updated should hold a primary key");
    
    // 表不存在
    if (![self jr_checkExistsTable4Clazz:[one class]]) {
        NSLog(@"table : %@ doesn't exists", [one class]);
        return NO;
    }
    
    NSObject<JRPersistent> *old = (NSObject *)[self jr_findByPrimaryKey:[one jr_primaryKeyValue] clazz:[one class]];
    NSObject<JRPersistent> *updateObj;
    if (columns.count) {
        if (!old) {
            NSLog(@"The object doesn't exists in database");
            return NO;
        }
        for (NSString *name in columns) {
            id value = [((NSObject *)one) valueForKey:name];
            [((NSObject *)old) setValue:value forKey:name];
        }
        updateObj = old;
    } else {
        updateObj = one;
    }
    
    NSArray *args;
    NSString *sql = [JRSqlGenerator sql4Update:updateObj columns:columns args:&args toDB:self];
    args = [args arrayByAddingObject:[updateObj jr_primaryKeyValue]];
    
    BOOL ret = [self executeUpdate:sql withArgumentsInArray:args];
    if (ret) {
        // 保存完，执行block
        if (ret) [one jr_executeFinishBlocks];
    }
    return ret;
}

- (BOOL)jr_updateOne:(id<JRPersistent>)one columns:(NSArray<NSString *> *)columns useTransaction:(BOOL)useTransaction {
    
    return
    
    [self jr_execute:^BOOL(FMDatabase * _Nonnull db) {
        BOOL needRollBack = ![self jr_updateOneOnly:one columns:columns];
        if (!needRollBack) {
            // 监测一对多的保存
            needRollBack = ![self jr_handleOneToManySaveWithObj:one columns:nil];
        }
        return !needRollBack;
    } useTransaction:useTransaction];
    

}

- (void)jr_updateOne:(id<JRPersistent>)one columns:(NSArray<NSString *> *)columns useTransaction:(BOOL)useTransaction complete:(JRDBComplete)complete {
    [self jr_inQueue:^(FMDatabase * _Nonnull db) {
        BOOL flag = [db jr_updateOne:one columns:columns useTransaction:useTransaction];
        EXE_BLOCK(complete, flag);
    }];
}

- (BOOL)jr_updateOne:(id<JRPersistent>)one columns:(NSArray<NSString *> *)columns {
    return [self jr_updateOne:one columns:columns useTransaction:YES];
}
- (void)jr_updateOne:(id<JRPersistent>)one columns:(NSArray<NSString *> *)columns complete:(JRDBComplete)complete {
    [self jr_updateOne:one columns:columns useTransaction:YES complete:complete];
}

#pragma mark - update array

- (BOOL)jr_updateObjects:(NSArray<id<JRPersistent>> *)objects columns:(NSArray<NSString *> *)columns useTransaction:(BOOL)useTransaction {
    return
    [self jr_execute:^BOOL(FMDatabase * _Nonnull db) {
        __block BOOL needRollBack = NO;
        [objects enumerateObjectsUsingBlock:^(id<JRPersistent>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            needRollBack = ![db jr_updateOne:obj columns:columns useTransaction:NO];
            *stop = needRollBack;
        }];
        return !needRollBack;
    } useTransaction:useTransaction];
}

- (void)jr_updateObjects:(NSArray<id<JRPersistent>> *)objects columns:(NSArray<NSString *> *)columns useTransaction:(BOOL)useTransaction complete:(JRDBComplete)complete {
    [self jr_inQueue:^(FMDatabase * _Nonnull db) {
        BOOL flag = [db jr_updateObjects:objects columns:columns useTransaction:useTransaction];
        EXE_BLOCK(complete, flag);
    }];
}

- (BOOL)jr_updateObjects:(NSArray<id<JRPersistent>> *)objects columns:(NSArray<NSString *> *)columns {
    return [self jr_updateObjects:objects columns:columns useTransaction:YES];
}

- (void)jr_updateObjects:(NSArray<id<JRPersistent>> *)objects columns:(NSArray<NSString *> *)columns complete:(JRDBComplete)complete {
    return [self jr_updateObjects:objects columns:columns useTransaction:YES complete:complete];
}

#pragma mark - delete

- (BOOL)jr_deleteOneOnly:(id<JRPersistent>)one {
    AssertRegisteredClazz([one class]);
    NSAssert([one jr_primaryKeyValue], @"primary key should not be nil");
    
    if (![self jr_checkExistsTable4Clazz:[one class]]) {
        NSLog(@"table : %@ doesn't exists", [one class]);
        return NO;
    }
    
    NSString *sql = [JRSqlGenerator sql4Delete:one];
    BOOL ret = [self executeUpdate:sql withArgumentsInArray:@[[one jr_primaryKeyValue]]];
    if (ret) {
        // 保存完，执行block
        [one jr_executeFinishBlocks];
    }
    return ret;
}

- (BOOL)jr_deleteOne:(id<JRPersistent>)one useTransaction:(BOOL)useTransaction {
    
    return
    
    [self jr_execute:^BOOL(FMDatabase * _Nonnull db) {
        __block BOOL needRollBack = ![self jr_deleteOneOnly:one];
        if (!needRollBack) {
            // 监测一对多的 中间表 删除
            [[[one class] jr_oneToManyLinkedPropertyNames] enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, Class<JRPersistent>  _Nonnull clazz, BOOL * _Nonnull stop) {
                JRMiddleTable *mid = [JRMiddleTable table4Clazz:clazz andClazz:[one class] db:self];
                needRollBack = ![mid deleteID:[one ID] forClazz:[one class]];
                *stop = needRollBack;
            }];
        }
        return !needRollBack;
    } useTransaction:useTransaction];
    
}

- (void)jr_deleteOne:(id<JRPersistent>)one useTransaction:(BOOL)useTransaction complete:(JRDBComplete)complete {
    [self jr_inQueue:^(FMDatabase * _Nonnull db) {
        BOOL flag = [db jr_deleteOne:one useTransaction:useTransaction];
        EXE_BLOCK(complete, flag);
    }];
}

- (BOOL)jr_deleteOne:(id<JRPersistent>)one {
    return [self jr_deleteOne:one useTransaction:YES];
}

- (void)jr_deleteOne:(id<JRPersistent>)one complete:(JRDBComplete)complete {
    [self jr_deleteOne:one useTransaction:YES complete:complete];
}

#pragma mark - delete array

/**
 *  删除array， 同时进行关联保存删除更新，可选择自带事务或者自行在外层包裹事务
 *
 *  @param objects
 *  @param useTransaction 若外层有事务，请用NO，若没有，请用YES
 */
- (BOOL)jr_deleteObjects:(NSArray<id<JRPersistent>> * _Nonnull)objects useTransaction:(BOOL)useTransaction {
    return
    [self jr_execute:^BOOL(FMDatabase * _Nonnull db) {
        __block BOOL needRollBack = NO;
        [objects enumerateObjectsUsingBlock:^(id<JRPersistent>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            needRollBack = ![db jr_deleteOne:obj useTransaction:NO];
            *stop = needRollBack;
        }];
        return !needRollBack;
    } useTransaction:useTransaction];
}
- (void)jr_deleteObjects:(NSArray<id<JRPersistent>> * _Nonnull)objects useTransaction:(BOOL)useTransaction complete:(JRDBComplete _Nullable)complete {
    [self jr_inQueue:^(FMDatabase * _Nonnull db) {
        BOOL flag = [self jr_deleteObjects:objects useTransaction:useTransaction];
        EXE_BLOCK(complete, flag);
    }];
}

- (BOOL)jr_deleteObjects:(NSArray<id<JRPersistent>> * _Nonnull)objects {
    return [self jr_deleteObjects:objects useTransaction:YES];
}
- (void)jr_deleteObjects:(NSArray<id<JRPersistent>> * _Nonnull)objects complete:(JRDBComplete _Nullable)complete {
    return [self jr_deleteObjects:objects useTransaction:YES complete:complete];
}


#pragma mark - single level query operation

- (id<JRPersistent>)jr_getByID:(NSString *)ID clazz:(Class<JRPersistent>)clazz {
    AssertRegisteredClazz(clazz);
    NSAssert(ID, @"id should not be nil");
    NSString *sql = [JRSqlGenerator sql4GetByIDWithClazz:clazz];
    FMResultSet *ret = [self executeQuery:sql withArgumentsInArray:@[ID]];
    return [JRFMDBResultSetHandler handleResultSet:ret forClazz:clazz].firstObject;
}

- (id<JRPersistent>)jr_getByPrimaryKey:(id)primaryKey clazz:(Class<JRPersistent>)clazz {
    AssertRegisteredClazz(clazz);
    NSAssert(primaryKey, @"id should be nil");
    NSString *sql = [JRSqlGenerator sql4GetByPrimaryKeyWithClazz:clazz];
    FMResultSet *ret = [self executeQuery:sql withArgumentsInArray:@[primaryKey]];
    return [JRFMDBResultSetHandler handleResultSet:ret forClazz:clazz].firstObject;
}

- (NSArray *)jr_getAll:(Class<JRPersistent>)clazz orderBy:(NSString *)orderby isDesc:(BOOL)isDesc {
    AssertRegisteredClazz(clazz);
    if (![self jr_checkExistsTable4Clazz:clazz]) {
        NSLog(@"table %@ doesn't exists", clazz);
        return @[];
    }
    NSString *sql = [JRSqlGenerator sql4FindAll:clazz orderby:orderby isDesc:isDesc];
    FMResultSet *ret = [self executeQuery:sql];
    return [JRFMDBResultSetHandler handleResultSet:ret forClazz:clazz];
}

- (NSArray *)jr_getByConditions:(NSArray<JRQueryCondition *> *)conditions clazz:(Class<JRPersistent>)clazz groupBy:(NSString *)groupBy orderBy:(NSString *)orderBy limit:(NSString *)limit isDesc:(BOOL)isDesc {
    AssertRegisteredClazz(clazz);
    if (![self jr_checkExistsTable4Clazz:clazz]) {
        NSLog(@"table %@ doesn't exists", clazz);
        return @[];
    }
    NSArray *args = nil;
    NSString *sql = [JRSqlGenerator sql4FindByConditions:conditions clazz:clazz groupBy:groupBy orderBy:orderBy limit:limit isDesc:isDesc args:&args];
    FMResultSet *ret = [self executeQuery:sql withArgumentsInArray:args];
    return [JRFMDBResultSetHandler handleResultSet:ret forClazz:clazz];
}

#pragma mark - multi level query operation

- (id<JRPersistent>)jr_objInStack:(NSArray *)array withID:(NSString *)ID {
    __block id<JRPersistent> obj = nil;
    [array enumerateObjectsUsingBlock:^(id<JRPersistent>  _Nonnull stackObj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([ID isEqualToString:[stackObj ID]]) {
            obj = stackObj;
            *stop = YES;
        }
    }];
    return obj;
}

- (id<JRPersistent>)jr_handleSingleLinkFindByID:(NSString *)ID clazz:(Class<JRPersistent>)clazz stack:(NSMutableArray<id<JRPersistent>> **)stack{
    id obj = [self jr_getByID:ID clazz:clazz];
    [[clazz jr_singleLinkedPropertyNames] enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, Class<JRPersistent>  _Nonnull subClazz, BOOL * _Nonnull stop) {
        NSString *subID = [((NSObject *)obj) jr_singleLinkIDforKey:key];
        if (subID) {
            [(*stack) addObject:obj];
            id<JRPersistent> exists = [self jr_objInStack:(*stack) withID:subID];
            if (!exists) {
                exists = [self jr_handleSingleLinkFindByID:subID clazz:subClazz stack:stack];
            }
            [obj setValue:exists forKey:key];
        }
    }];
    return obj;
}

- (id<JRPersistent>)jr_findByID:(NSString *)ID clazz:(Class<JRPersistent>)clazz {
    NSMutableArray *array = [NSMutableArray array];
    NSObject<JRPersistent> *obj = [self jr_handleSingleLinkFindByID:ID clazz:clazz stack:&array];
    
    // 检查有无查询一对多
    [[[obj class] jr_oneToManyLinkedPropertyNames] enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, Class<JRPersistent>  _Nonnull clazz, BOOL * _Nonnull stop) {
        
        JRMiddleTable *mid = [JRMiddleTable table4Clazz:clazz andClazz:[obj class] db:self];
        NSArray *ids = [mid anotherClazzIDsWithID:[obj ID] clazz:[obj class]];
        
        NSMutableArray *subList = [NSMutableArray array];
        [ids enumerateObjectsUsingBlock:^(id  _Nonnull aID, NSUInteger idx, BOOL * _Nonnull stop) {
            id sub = [self jr_findByID:aID clazz:clazz];
            if (sub) {
                [subList addObject:sub];
            }
        }];
        [obj setValue:subList forKey:key];
    }];
    
    return obj;
}

- (id<JRPersistent>)jr_findByPrimaryKey:(id)primaryKey clazz:(Class<JRPersistent>)clazz {
    if (![self jr_checkExistsTable4Clazz:clazz]) {
        NSLog(@"table %@ doesn't exists", clazz);
        return nil;
    }
    NSObject<JRPersistent> *obj = [self jr_getByPrimaryKey:primaryKey clazz:clazz];
    return [self jr_findByID:[obj ID] clazz:[obj class]];
}


- (NSArray *)jr_findAll:(Class<JRPersistent>)clazz {
    return [self jr_findAll:clazz orderBy:nil isDesc:NO];
}

- (NSArray *)jr_findAll:(Class<JRPersistent>)clazz orderBy:(NSString *)orderby isDesc:(BOOL)isDesc {
    NSArray *list = [self jr_getAll:clazz orderBy:orderby isDesc:isDesc];
    NSMutableArray *result = [NSMutableArray array];
    
    [list enumerateObjectsUsingBlock:^(id<JRPersistent>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [result addObject:[self jr_findByID:[obj ID] clazz:[obj class]]];
    }];
    
    return result;
}

- (NSArray *)jr_findByConditions:(NSArray<JRQueryCondition *> *)conditions
                        clazz:(Class<JRPersistent>)clazz
                      groupBy:(NSString *)groupBy
                      orderBy:(NSString *)orderBy
                        limit:(NSString *)limit
                       isDesc:(BOOL)isDesc {
    
    NSArray<id<JRPersistent>> *list = [self jr_getByConditions:conditions
                                                      clazz:clazz
                                                    groupBy:groupBy
                                                    orderBy:orderBy
                                                      limit:limit
                                                     isDesc:isDesc];
    
    NSMutableArray *result = [NSMutableArray array];
    [list enumerateObjectsUsingBlock:^(id<JRPersistent>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [result addObject:[self jr_findByID:[obj ID] clazz:[obj class]]];
    }];
    
    return result;
}

- (NSArray *)jr_findByConditions:(NSArray<JRQueryCondition *> *)conditions clazz:(Class<JRPersistent>)clazz isDesc:(BOOL)isDesc {
    return [self jr_findByConditions:conditions clazz:clazz groupBy:nil orderBy:nil limit:nil isDesc:isDesc];
}

- (NSArray *)jr_findByConditions:(NSArray<JRQueryCondition *> *)conditions clazz:(Class<JRPersistent>)clazz groupBy:(NSString *)groupBy isDesc:(BOOL)isDesc {
    return [self jr_findByConditions:conditions clazz:clazz groupBy:groupBy orderBy:nil limit:nil isDesc:isDesc];
}
- (NSArray *)jr_findByConditions:(NSArray<JRQueryCondition *> *)conditions clazz:(Class<JRPersistent>)clazz orderBy:(NSString *)orderBy isDesc:(BOOL)isDesc {
    return [self jr_findByConditions:conditions clazz:clazz groupBy:nil orderBy:orderBy limit:nil isDesc:isDesc];
}
- (NSArray *)jr_findByConditions:(NSArray<JRQueryCondition *> *)conditions clazz:(Class<JRPersistent>)clazz limit:(NSString *)limit isDesc:(BOOL)isDesc {
    return [self jr_findByConditions:conditions clazz:clazz groupBy:nil orderBy:nil limit:limit isDesc:isDesc];
}

#pragma mark - convenience method
- (BOOL)jr_checkExistsTable4Clazz:(Class<JRPersistent>)clazz {
    AssertRegisteredClazz(clazz);
    return [self tableExists:[clazz shortClazzName]];
}

@end


