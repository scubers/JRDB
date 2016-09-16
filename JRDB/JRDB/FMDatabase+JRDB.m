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
#import "JRActivatedProperty.h"
#import "JRDBQueue.h"


#define AssertRegisteredClazz(clazz) NSAssert([[JRDBMgr shareInstance] isValidClazz:clazz], @"class: %@ should be registered in JRDBMgr", clazz)

static NSString * const jrdb_synchronizing = @"jrdb_synchronizing";

@implementation FMDatabase (JRDB)

- (void)jr_inQueue:(void (^)(FMDatabase *))block {
    [[JRDBMgr shareInstance].queues[self.databasePath] inDatabase:^(FMDatabase *db) {
        EXE_BLOCK(block, db);
    }];
}

- (BOOL)jr_inTransaction:(void (^)(FMDatabase *, BOOL *))block {
    return
    [[self jr_executeSync:YES block:^id _Nullable(FMDatabase * _Nonnull db) {
        
        BOOL rollback = ![db beginTransaction];
        if (rollback) {
            NSLog(@"begin transaction fail");
            return @(!rollback);
        }
        rollback = NO;
        EXE_BLOCK(block, db, &rollback);
        if (rollback) {
            NSLog(@"warning: execute error, database will roll back!!");
            [self rollback];
            return @NO;
        } else {
            rollback = ![db commit];
        }
        return @(!rollback);
    }] boolValue];
}

- (BOOL)jr_execute:(BOOL (^)(FMDatabase * _Nonnull db))block useTransaction:(BOOL)useTransaction {
    if (useTransaction) {
        if ([self inTransaction]) {
            NSLog(@"operation has open a transaction already, will not open again");
            return block(self);
        } else if (![self beginTransaction]) {
            NSLog(@"begin a transaction error");
            return NO;
        }
    }
    BOOL flag = block(self);
    if (useTransaction) {
        if (flag) {
            return [self commit];
        } else {
            [self rollback];
            return NO;
        }
    }
    return flag;
}

- (id)jr_executeSync:(BOOL)sync block:(id (^)(FMDatabase *db))block {
    if (sync && ![[[JRDBMgr shareInstance] queueWithPath:self.databasePath] isInCurrentQueue]) {
        __block id result;
        [self jr_inQueue:^(FMDatabase * _Nonnull db) {
            result = block(db);
        }];
        return result;
    } else {
        return block(self);
    }
}

- (FMResultSet *)jr_executeQuery:(JRSql *)sql {
    return [self executeQuery:sql.sqlString withArgumentsInArray:sql.args];
}

- (BOOL)jr_executeUpdate:(JRSql *)sql {
    return [self executeUpdate:sql.sqlString withArgumentsInArray:sql.args];
}

@end

#pragma mark - table operation
@implementation FMDatabase (JRDBTable)

- (BOOL)jr_createTable4Clazz:(Class<JRPersistent>)clazz {
    
    AssertRegisteredClazz(clazz);
    
    if (![self jr_checkExistsTable4Clazz:clazz]) {
        return [self jr_executeUpdate:[JRSqlGenerator createTableSql4Clazz:clazz table:nil]];
    }
    return YES;
}

- (BOOL)jr_createTable4Clazz:(Class<JRPersistent>)clazz synchronized:(BOOL)synchronized complete:(JRDBComplete)complete {
    return
    [[self jr_executeSync:synchronized block:^id(FMDatabase *db) {
        return @([db jr_inTransaction:^(FMDatabase *db, BOOL *rollBack) {
            BOOL flag = [db jr_createTable4Clazz:clazz];
            *rollBack = !flag;
            EXE_BLOCK(complete, flag);
        }]);
    }] boolValue];
}

- (BOOL)jr_truncateTable4Clazz:(Class<JRPersistent>)clazz {
    AssertRegisteredClazz(clazz);
    if ([self jr_checkExistsTable4Clazz:clazz]) {
        [self jr_executeUpdate:[JRSqlGenerator dropTableSql4Clazz:clazz table:nil]];
    }
    return [self jr_createTable4Clazz:clazz];
}

- (BOOL)jr_truncateTable4Clazz:(Class<JRPersistent>)clazz synchronized:(BOOL)synchronized complete:(JRDBComplete)complete {
    return
    [[self jr_executeSync:synchronized block:^id(FMDatabase *db) {
        return @([db jr_inTransaction:^(FMDatabase *db, BOOL *rollBack) {
            BOOL flag = [db jr_truncateTable4Clazz:clazz];
            *rollBack = !flag;
            EXE_BLOCK(complete, flag);
        }]);
    }] boolValue];
}

- (BOOL)jr_updateTable4Clazz:(Class<JRPersistent>)clazz {
    AssertRegisteredClazz(clazz);
    NSArray *sqls = [JRSqlGenerator updateTableSql4Clazz:clazz inDB:self table:nil];
    BOOL flag = YES;
    for (JRSql *sql in sqls) {
        flag = [self jr_executeUpdate:sql];
        if (!flag) {
            break;
        }
    }
    return flag;
}

- (BOOL)jr_updateTable4Clazz:(Class<JRPersistent>)clazz synchronized:(BOOL)synchronized complete:(JRDBComplete)complete {
    return
    [[self jr_executeSync:synchronized block:^id(FMDatabase *db) {
        return @([db jr_inTransaction:^(FMDatabase *db, BOOL *rollBack) {
            BOOL flag = [db jr_updateTable4Clazz:clazz];
            *rollBack = !flag;
            EXE_BLOCK(complete, flag);
        }]);
    }] boolValue];
}

- (BOOL)jr_dropTable4Clazz:(Class<JRPersistent>)clazz {
    AssertRegisteredClazz(clazz);
    if ([self jr_checkExistsTable4Clazz:clazz]) {
        return [self executeUpdate:[JRSqlGenerator dropTableSql4Clazz:clazz table:nil].sqlString];
    }
    return YES;
}

- (BOOL)jr_dropTable4Clazz:(Class<JRPersistent>)clazz synchronized:(BOOL)synchronized complete:(JRDBComplete)complete {
    return
    [[self jr_executeSync:synchronized block:^id(FMDatabase *db) {
        return @([db jr_inTransaction:^(FMDatabase *db, BOOL *rollBack) {
            BOOL flag = [db jr_dropTable4Clazz:clazz];
            *rollBack = !flag;
            EXE_BLOCK(complete, flag);
        }]);
    }] boolValue];
}

- (BOOL)jr_checkExistsTable4Clazz:(Class<JRPersistent>)clazz {
    AssertRegisteredClazz(clazz);
    return [self tableExists:[clazz shortClazzName]];
}

- (NSArray<JRColumnSchema *> *)jr_schemasInClazz:(Class<JRPersistent>)clazz {
    AssertRegisteredClazz(clazz);
    FMResultSet *ret = [[JRDBMgr defaultDB] getTableSchema:[clazz shortClazzName]];
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
    [ret close];
    return schemas;
}

@end

#pragma mark - save or update

@implementation FMDatabase (JRDBSaveOrUpdate)

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
                    [self jr_updateOne:obj columns:@[key] useTransaction:NO synchronized:NO complete:nil];
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
        old = [self jr_getByPrimaryKey:[obj jr_primaryKeyValue] clazz:[obj class] synchronized:NO complete:nil];
    }

    if (!old) {
        BOOL ret = [self jr_saveOneOnly:obj useTransaction:NO synchronized:NO complete:nil];
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
        
        if (!(!columns || [columns containsObject:key])) { return; }
        
        NSArray *array = [((NSObject *)obj) valueForKey:key];
        // 逐个保存
        [array enumerateObjectsUsingBlock:^(NSObject<JRPersistent> * _Nonnull subObj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (![subObj ID]) {
                // 设置父ID
                if ([obj class] == clazz) {
                    [subObj jr_setParentLinkID:[obj ID] forKey:key];
                }
                needRollBack = ![self jr_saveOne:subObj useTransaction:NO synchronized:NO complete:nil];
                *stop = needRollBack;
            }
        }];
        
        if ([obj class] != clazz) {// 如果是同一张表则不需要中间表，是父子关系
            // 保存中建表
            JRMiddleTable *mid = [JRMiddleTable table4Clazz:clazz andClazz:[obj class] db:self];
            needRollBack = ![mid saveObjs:array forObj:obj];
        }
        *stop = needRollBack;
    }];
    return !needRollBack;
}

#pragma mark - save or update

- (BOOL)jr_saveOrUpdateOneOnly:(id<JRPersistent> _Nonnull)one useTransaction:(BOOL)useTransaction {
    AssertRegisteredClazz([one class]);
    return
    [self jr_execute:^BOOL(FMDatabase * _Nonnull db) {
        BOOL isSave = YES;
        if ([[one class] jr_customPrimarykey]) { // 自定义主键
            NSAssert([one jr_customPrimarykeyValue] != nil, @"custom Primary key should not be nil");
            isSave = ![self jr_count4PrimaryKey:[one jr_customPrimarykeyValue] clazz:[one class] synchronized:NO  complete:nil];
        } else { // 默认主键
            isSave = !one.ID;
        }
        
        if (isSave) {
            return [self jr_saveOneOnly:one useTransaction:NO synchronized:NO complete:nil];
        } else {
            return [self jr_updateOneOnly:one columns:nil useTransaction:NO synchronized:NO complete:nil];
        }
    } useTransaction:useTransaction];
}

- (BOOL)jr_saveOrUpdateOneOnly:(id<JRPersistent>)one useTransaction:(BOOL)useTransaction synchronized:(BOOL)synchronized complete:(JRDBComplete)complete {
    return
    [[self jr_executeSync:synchronized block:^id(FMDatabase *db) {
        BOOL flag = [db jr_saveOrUpdateOneOnly:one useTransaction:useTransaction];
        EXE_BLOCK(complete, flag);
        return @(flag);
    }] boolValue];
}

- (BOOL)jr_saveOrUpdateOne:(id<JRPersistent>)one useTransaction:(BOOL)useTransaction {
    BOOL isSave = YES;
    if ([[one class] jr_customPrimarykey]) { // 自定义主键
        NSAssert([one jr_customPrimarykeyValue] != nil, @"custom Primary key should not be nil");
        isSave = ![self jr_count4PrimaryKey:[one jr_customPrimarykeyValue] clazz:[one class] synchronized:NO complete:nil];
    } else { // 默认主键
        isSave = !one.ID;
    }
    if (isSave) {
        return [self jr_saveOne:one useTransaction:useTransaction synchronized:NO complete:nil];
    } else {
        return [self jr_updateOne:one columns:nil useTransaction:useTransaction synchronized:NO complete:nil];
    }
}

- (BOOL)jr_saveOrUpdateOne:(id<JRPersistent>)one useTransaction:(BOOL)useTransaction synchronized:(BOOL)synchronized complete:(JRDBComplete)complete {
    return
    [[self jr_executeSync:synchronized block:^id(FMDatabase *db) {
        BOOL flag = [db jr_saveOrUpdateOne:one useTransaction:useTransaction];
        EXE_BLOCK(complete, flag);
        return @(flag);
    }] boolValue];
}

#pragma mark - save or update array

- (BOOL)jr_saveOrUpdateObjectsOnly:(NSArray<id<JRPersistent>> * _Nonnull)objects useTransaction:(BOOL)useTransaction {
    return
    [self jr_execute:^BOOL(FMDatabase * _Nonnull db) {
        __block BOOL needRollBack = NO;
        [objects enumerateObjectsUsingBlock:^(id<JRPersistent>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            needRollBack = ![db jr_saveOrUpdateOneOnly:obj useTransaction:NO];
            *stop = needRollBack;
        }];
        return !needRollBack;
    } useTransaction:useTransaction];
}

- (BOOL)jr_saveOrUpdateObjectsOnly:(NSArray<id<JRPersistent>> *)objects useTransaction:(BOOL)useTransaction synchronized:(BOOL)synchronized complete:(JRDBComplete)complete {
    return
    [[self jr_executeSync:synchronized block:^id(FMDatabase *db) {
        BOOL flag = [db jr_saveOrUpdateObjectsOnly:objects useTransaction:useTransaction];
        EXE_BLOCK(complete, flag);
        return @(flag);
    }] boolValue];
}

- (BOOL)jr_saveOrUpdateObjects:(NSArray<id<JRPersistent>> * _Nonnull)objects useTransaction:(BOOL)useTransaction {
    return
    [self jr_execute:^BOOL(FMDatabase * _Nonnull db) {
        __block BOOL needRollBack = NO;
        [objects enumerateObjectsUsingBlock:^(id<JRPersistent>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            needRollBack = ![db jr_saveOrUpdateOne:obj useTransaction:NO];
            *stop = needRollBack;
        }];
        return !needRollBack;
    } useTransaction:useTransaction];
}

- (BOOL)jr_saveOrUpdateObjects:(NSArray<id<JRPersistent>> * _Nonnull)objects useTransaction:(BOOL)useTransaction synchronized:(BOOL)synchronized complete:(JRDBComplete _Nullable)complete {
    return
    [[self jr_executeSync:synchronized block:^id(FMDatabase *db) {
        BOOL flag = [db jr_saveOrUpdateObjects:objects useTransaction:useTransaction];
        EXE_BLOCK(complete, flag);
        return @(flag);
    }] boolValue];
}

@end

#pragma mark - save
@implementation FMDatabase (JRDBSave)

- (BOOL)jr_saveOneOnly:(id<JRPersistent> _Nonnull)one useTransaction:(BOOL)useTransaction {
    return
    [self jr_execute:^BOOL(FMDatabase * _Nonnull db) {
        AssertRegisteredClazz([one class]);
        
        if (![self jr_checkExistsTable4Clazz:[one class]]) {
            BOOL result = [self jr_createTable4Clazz:[one class]];
            if (!result) {
                NSLog(@"create table error");
                return NO;
            }
        }
        
        if ([[one class] jr_customPrimarykey]) { // 自定义主键
            NSAssert([one jr_customPrimarykeyValue] != nil, @"custom Primary key should not be nil");
            long count = [self jr_count4PrimaryKey:[one jr_customPrimarykeyValue] clazz:[one class] synchronized:NO  complete:nil];
            if (count) {
                NSLog(@"warning: save error, primary key is exists");
                return NO;
            }
        } else { // 默认主键
            NSAssert(one.ID == nil, @"The obj:%@ to be saved should not hold a ID", one);
        }
        
        JRSql *sql = [JRSqlGenerator sql4Insert:one toDB:self table:nil];
        [one setID:[JRUtils uuid]];
        [sql.args insertObject:one.ID atIndex:0];
        BOOL ret = [self jr_executeUpdate:sql];
        
        if (ret) {
            // 保存完，执行block
            [one jr_executeFinishBlocks];
        }
        return ret;
    } useTransaction:useTransaction];
}

- (BOOL)jr_saveOneOnly:(id<JRPersistent>)one useTransaction:(BOOL)useTransaction synchronized:(BOOL)synchronized complete:(JRDBComplete)complete {
    return
    [[self jr_executeSync:synchronized block:^id(FMDatabase *db) {
        BOOL flag = [db jr_saveOneOnly:one useTransaction:useTransaction];
        EXE_BLOCK(complete, flag);
        return @(flag);
    }] boolValue];
}

- (BOOL)jr_saveOne:(id<JRPersistent>)one useTransaction:(BOOL)useTransaction {
    AssertRegisteredClazz([one class]);
    
    return
    
    [self jr_execute:^BOOL(FMDatabase * _Nonnull db) {
        
        NSMutableArray *stack = [NSMutableArray array];
        __block BOOL needRollBack = NO;
        [db jr_handleSave:one stack:&stack needRollBack:&needRollBack];
        
        if (!needRollBack) {
            // 监测一对多的保存 此时的 [one ID] 为 nil
            needRollBack = ![db jr_handleOneToManySaveWithObj:one columns:nil];
        }
        return !needRollBack;
        
    } useTransaction:useTransaction];
    
}

- (BOOL)jr_saveOne:(id<JRPersistent>)one useTransaction:(BOOL)useTransaction synchronized:(BOOL)synchronized complete:(JRDBComplete)complete {
    return
    [[self jr_executeSync:synchronized block:^id(FMDatabase *db) {
        BOOL flag = [db jr_saveOne:one useTransaction:useTransaction];
        EXE_BLOCK(complete, flag);
        return @(flag);
    }] boolValue];
}


#pragma mark - save array

- (BOOL)jr_saveObjectsOnly:(NSArray<id<JRPersistent>> *)objects useTransaction:(BOOL)useTransaction {
    return
    [self jr_execute:^BOOL(FMDatabase * _Nonnull db) {
        __block BOOL needRollBack = NO;
        [objects enumerateObjectsUsingBlock:^(id<JRPersistent>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            needRollBack = ![db jr_saveOneOnly:obj useTransaction:NO];
            *stop = needRollBack;
        }];
        return !needRollBack;
    } useTransaction:useTransaction];
}

- (BOOL)jr_saveObjectsOnly:(NSArray<id<JRPersistent>> *)objects useTransaction:(BOOL)useTransaction synchronized:(BOOL)synchronized complete:(JRDBComplete)complete {
    return
    [[self jr_executeSync:synchronized block:^id(FMDatabase *db) {
        BOOL flag = [db jr_saveObjectsOnly:objects useTransaction:useTransaction];
        EXE_BLOCK(complete, flag);
        return @(flag);
    }] boolValue];
}

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

- (BOOL)jr_saveObjects:(NSArray<id<JRPersistent>> *)objects useTransaction:(BOOL)useTransaction synchronized:(BOOL)synchronized complete:(JRDBComplete)complete {
    return
    [[self jr_executeSync:synchronized block:^id(FMDatabase *db) {
        BOOL flag = [db jr_saveObjects:objects useTransaction:useTransaction];
        EXE_BLOCK(complete, flag);
        return @(flag);
    }] boolValue];
}

@end

#pragma mark - update


@implementation FMDatabase (JRDBUpdate)

/**
 *  只更新数据，不进行关联操作
 *
 *  @param obj
 *  @param columns
 */
- (BOOL)jr_updateOneOnly:(id<JRPersistent>)one columns:(NSArray<NSString *> *)columns useTransaction:(BOOL)useTransaction {
    AssertRegisteredClazz([one class]);
    NSAssert([one jr_primaryKeyValue], @"The obj to be updated should hold a primary key");
    
    return
    [self jr_execute:^BOOL(FMDatabase * _Nonnull db) {
        // 表不存在
        if (![self jr_checkExistsTable4Clazz:[one class]]) {
            NSLog(@"table : %@ doesn't exists", [one class]);
            return NO;
        }
        
        NSObject<JRPersistent> *old = (NSObject *)[self jr_findByPrimaryKey:[one jr_primaryKeyValue] clazz:[one class] synchronized:NO complete:nil];
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
        
        JRSql *sql = [JRSqlGenerator sql4Update:updateObj columns:columns toDB:self table:nil];
        [sql.args addObject:[updateObj jr_primaryKeyValue]];
        
        BOOL ret = [self jr_executeUpdate:sql];
        if (ret) {
            // 保存完，执行block
            if (ret) [one jr_executeFinishBlocks];
        }
        return ret;
    } useTransaction:useTransaction];
    
}

- (BOOL)jr_updateOneOnly:(id<JRPersistent>)one columns:(NSArray<NSString *> *)columns useTransaction:(BOOL)useTransaction synchronized:(BOOL)synchronized complete:(JRDBComplete _Nullable)complete {
    
    //清除缓存
    if ([one ID]) {
        [self removeObjInRecursiveCache:[one ID]];
        [self removeObjInUnRecursiveCache:[one ID]];
    }
    
    return
    [[self jr_executeSync:synchronized block:^id(FMDatabase *db) {
        BOOL flag = [db jr_updateOneOnly:one columns:columns useTransaction:useTransaction];
        EXE_BLOCK(complete, flag);
        return @(flag);
    }] boolValue];
}

- (BOOL)jr_updateOne:(id<JRPersistent>)one columns:(NSArray<NSString *> *)columns useTransaction:(BOOL)useTransaction {
    
    return
    
    [self jr_execute:^BOOL(FMDatabase * _Nonnull db) {
        __block BOOL needRollBack = ![self jr_updateOneOnly:one columns:columns useTransaction:NO];
        
        // 检测一对一是否需要更新持有id
        if (!needRollBack) {
            NSObject<JRPersistent> *oneObj = (NSObject<JRPersistent> *)one;
            [[[one class] jr_singleLinkedPropertyNames] enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, Class<JRPersistent>  _Nonnull clazz, BOOL * _Nonnull stop) {
                if (![columns containsObject:key]) { return;}
                id<JRPersistent> subObj = [oneObj valueForKey:key];
                if (subObj && ![subObj ID]) {
                    needRollBack = ![self jr_saveOne:subObj useTransaction:NO];
                    *stop = needRollBack;
                }
                [oneObj jr_setSingleLinkID:[subObj ID] forKey:key];
                needRollBack = ![self jr_updateOneOnly:oneObj columns:columns useTransaction:NO];
                *stop = needRollBack;
            }];
        }
        
        // TODO: 更新时，是否保存一对多，需要检讨
        if (!needRollBack) {
            // 监测一对多的保存
            needRollBack = ![self jr_handleOneToManySaveWithObj:one columns:columns];
        }
        return !needRollBack;
    } useTransaction:useTransaction];
    

}

- (BOOL)jr_updateOne:(id<JRPersistent>)one columns:(NSArray<NSString *> *)columns useTransaction:(BOOL)useTransaction synchronized:(BOOL)synchronized complete:(JRDBComplete)complete {
    return
    [[self jr_executeSync:synchronized block:^id(FMDatabase *db) {
        BOOL flag = [db jr_updateOne:one columns:columns useTransaction:useTransaction];
        EXE_BLOCK(complete, flag);
        return @(flag);
    }] boolValue];
}


#pragma mark - update array

- (BOOL)jr_updateObjectsOnly:(NSArray<id<JRPersistent>> *)objects columns:(NSArray<NSString *> *)columns useTransaction:(BOOL)useTransaction {
    return
    [self jr_execute:^BOOL(FMDatabase * _Nonnull db) {
        __block BOOL needRollBack = NO;
        [objects enumerateObjectsUsingBlock:^(id<JRPersistent>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            needRollBack = ![db jr_updateOneOnly:obj columns:columns useTransaction:NO];
            *stop = needRollBack;
        }];
        return !needRollBack;
    } useTransaction:useTransaction];
}

- (BOOL)jr_updateObjectsOnly:(NSArray<id<JRPersistent>> *)objects columns:(NSArray<NSString *> *)columns useTransaction:(BOOL)useTransaction synchronized:(BOOL)synchronized complete:(JRDBComplete)complete {
    return
    [[self jr_executeSync:synchronized block:^id(FMDatabase *db) {
        BOOL flag = [db jr_updateObjectsOnly:objects columns:columns useTransaction:useTransaction];
        EXE_BLOCK(complete, flag);
        return @(flag);
    }] boolValue];
}

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

- (BOOL)jr_updateObjects:(NSArray<id<JRPersistent>> *)objects columns:(NSArray<NSString *> *)columns useTransaction:(BOOL)useTransaction synchronized:(BOOL)synchronized complete:(JRDBComplete)complete {
    return
    [[self jr_executeSync:synchronized block:^id(FMDatabase *db) {
        BOOL flag = [db jr_updateObjects:objects columns:columns useTransaction:useTransaction];
        EXE_BLOCK(complete, flag);
        return @(flag);
    }] boolValue];
}

@end

#pragma mark - delete

@implementation FMDatabase (JRDBDelete)

- (BOOL)jr_deleteOneOnly:(id<JRPersistent>)one useTransaction:(BOOL)useTransaction {
    AssertRegisteredClazz([one class]);
    NSAssert([one jr_primaryKeyValue], @"primary key should not be nil");
    return
    [self jr_execute:^BOOL(FMDatabase * _Nonnull db) {
        if (![self jr_checkExistsTable4Clazz:[one class]]) {
            NSLog(@"table : %@ doesn't exists", [one class]);
            return NO;
        }
        
        JRSql *sql = [JRSqlGenerator sql4Delete:one table:nil];
        [sql.args addObject:[one jr_primaryKeyValue]];
        BOOL ret = [self jr_executeUpdate:sql];
        if (ret) {
            // 保存完，执行block
            [one jr_executeFinishBlocks];
        }
        return ret;
    } useTransaction:useTransaction];
}

- (BOOL)jr_deleteOneOnly:(id<JRPersistent>)one useTransaction:(BOOL)useTransaction synchronized:(BOOL)synchronized complete:(JRDBComplete)complete {
    return
    [[self jr_executeSync:synchronized block:^id(FMDatabase *db) {
        BOOL flag = [db jr_deleteOneOnly:one useTransaction:useTransaction];
        EXE_BLOCK(complete, flag);
        return @(flag);
    }] boolValue];
}

- (BOOL)jr_deleteOne:(id<JRPersistent>)one useTransaction:(BOOL)useTransaction {
    
    return
    
    [self jr_execute:^BOOL(FMDatabase * _Nonnull db) {
        __block BOOL needRollBack = ![self jr_deleteOneOnly:one useTransaction:NO];
        if (!needRollBack) {
            // 监测一对多的 中间表 删除
            [[[one class] jr_oneToManyLinkedPropertyNames] enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, Class<JRPersistent>  _Nonnull clazz, BOOL * _Nonnull stop) {
                
                if ([one class] == clazz) {// 同类父子关系
                    NSString *condition = [NSString stringWithFormat:@"%@ = ?", ParentLinkColumn(key)];
                    NSArray *children = [self jr_findByConditions:@[
                                                                    [JRQueryCondition condition:condition args:@[[one ID]] type:JRQueryConditionTypeAnd]
                                                                    ]
                                                            clazz:clazz
                                                          groupBy:nil
                                                          orderBy:nil
                                                            limit:nil
                                                           isDesc:NO
                                                     synchronized:NO
                                                         useCache:NO    
                                                         complete:nil];
                    needRollBack = ![self jr_deleteObjects:children useTransaction:NO];
                } else {
                    JRMiddleTable *mid = [JRMiddleTable table4Clazz:clazz andClazz:[one class] db:self];
                    needRollBack = ![mid deleteID:[one ID] forClazz:[one class]];
                }
                *stop = needRollBack;
            }];
        }
        return !needRollBack;
    } useTransaction:useTransaction];
    
}

- (BOOL)jr_deleteOne:(id<JRPersistent>)one useTransaction:(BOOL)useTransaction synchronized:(BOOL)synchronized complete:(JRDBComplete)complete {
    return
    [[self jr_executeSync:synchronized block:^id(FMDatabase *db) {
        BOOL flag = [db jr_deleteOne:one useTransaction:useTransaction];
        EXE_BLOCK(complete, flag);
        return @(flag);
    }] boolValue];
}

#pragma mark - delete array

- (BOOL)jr_deleteObjectsOnly:(NSArray<id<JRPersistent>> *)objects useTransaction:(BOOL)useTransaction {
    return
    [self jr_execute:^BOOL(FMDatabase * _Nonnull db) {
        __block BOOL needRollBack = NO;
        [objects enumerateObjectsUsingBlock:^(id<JRPersistent>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            needRollBack = ![db jr_deleteOneOnly:obj useTransaction:NO];
            *stop = needRollBack;
        }];
        return !needRollBack;
    } useTransaction:useTransaction];
}

- (BOOL)jr_deleteObjectsOnly:(NSArray<id<JRPersistent>> *)objects useTransaction:(BOOL)useTransaction synchronized:(BOOL)synchronized complete:(JRDBComplete)complete {
    return
    [[self jr_executeSync:synchronized block:^id(FMDatabase *db) {
        BOOL flag = [db jr_deleteObjectsOnly:objects useTransaction:useTransaction];
        EXE_BLOCK(complete, flag);
        return @(flag);
    }] boolValue];
}

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
- (BOOL)jr_deleteObjects:(NSArray<id<JRPersistent>> * _Nonnull)objects useTransaction:(BOOL)useTransaction synchronized:(BOOL)synchronized complete:(JRDBComplete _Nullable)complete {
    return
    [[self jr_executeSync:synchronized block:^id(FMDatabase *db) {
        BOOL flag = [db jr_deleteObjects:objects useTransaction:useTransaction];
        EXE_BLOCK(complete, flag);
        return @(flag);
    }] boolValue];
}

#pragma mark - delete all

- (BOOL)jr_deleteAllOnly:(Class<JRPersistent>)clazz useTransaction:(BOOL)useTransaction {
    AssertRegisteredClazz(clazz);
    return
    [self jr_execute:^BOOL(FMDatabase * _Nonnull db) {
        JRSql *sql = [JRSqlGenerator sql4DeleteAll:clazz table:nil];
        return [self jr_executeUpdate:sql];
    } useTransaction:useTransaction];
}

- (BOOL)jr_deleteAllOnly:(Class<JRPersistent>)clazz useTransaction:(BOOL)useTransaction synchronized:(BOOL)synchronized complete:(JRDBComplete)complete {
    return
    [[self jr_executeSync:synchronized block:^id(FMDatabase *db) {
        BOOL flag = [db jr_deleteAllOnly:clazz useTransaction:useTransaction];
        EXE_BLOCK(complete, flag);
        return @(flag);
    }] boolValue];
}

- (BOOL)jr_deleteAll:(Class<JRPersistent> _Nonnull)clazz useTransaction:(BOOL)useTransaction {
    NSArray<id<JRPersistent>> *objects = [self jr_getByConditions:nil clazz:clazz groupBy:nil orderBy:nil limit:nil isDesc:NO synchronized:NO complete:nil];
    return [self jr_deleteObjects:objects useTransaction:useTransaction];
}

- (BOOL)jr_deleteAll:(Class<JRPersistent> _Nonnull)clazz useTransaction:(BOOL)useTransaction synchronized:(BOOL)synchronized complete:(JRDBComplete _Nullable)complete {
    return
    [[self jr_executeSync:synchronized block:^id(FMDatabase *db) {
        BOOL flag = [db jr_deleteAll:clazz useTransaction:useTransaction];
        EXE_BLOCK(complete, flag);
        return @(flag);
    }] boolValue];
}

@end

#pragma mark - query

@implementation FMDatabase (JRDBQuery)

- (id<JRPersistent>)jr_getByID:(NSString *)ID clazz:(Class<JRPersistent>)clazz {
    AssertRegisteredClazz(clazz);
    NSAssert(ID, @"id should not be nil");
    JRSql *sql = [JRSqlGenerator sql4GetByIDWithClazz:clazz ID:ID table:nil];
    FMResultSet *ret = [self jr_executeQuery:sql];
    return [JRFMDBResultSetHandler handleResultSet:ret forClazz:clazz columns:nil].firstObject;
}

- (id<JRPersistent>)jr_getByID:(NSString *)ID clazz:(Class<JRPersistent>)clazz synchronized:(BOOL)synchronized useCache:(BOOL)useCache complete:(JRDBQueryComplete)complete {
    
    if (useCache) {
        id<JRPersistent> cacheObj = [self objInUnRecursiveCache:ID];
        if (cacheObj) {
            objc_setAssociatedObject(cacheObj, @selector(isCacheHit), @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            EXE_BLOCK(complete, cacheObj);
            return cacheObj;
        }
    }
    
    return
    [self jr_executeSync:synchronized block:^id(FMDatabase *db) {
        id<JRPersistent> result = [db jr_getByID:ID clazz:clazz];
        
        if (result) {[db saveObjInUnRecursiveCache:result];}
        
        EXE_BLOCK(complete, result);
        return result;
    }];
}

- (id<JRPersistent>)jr_getByPrimaryKey:(id)primaryKey clazz:(Class<JRPersistent>)clazz {
    AssertRegisteredClazz(clazz);
    NSAssert(primaryKey, @"id should be nil");
    JRSql *sql = [JRSqlGenerator sql4GetByPrimaryKeyWithClazz:clazz primaryKey:primaryKey table:nil];
    FMResultSet *ret = [self jr_executeQuery:sql];
    return [JRFMDBResultSetHandler handleResultSet:ret forClazz:clazz columns:nil].firstObject;
}

- (id<JRPersistent>)jr_getByPrimaryKey:(id)primaryKey clazz:(Class<JRPersistent>)clazz synchronized:(BOOL)synchronized complete:(JRDBQueryComplete)complete {
    return
    [self jr_executeSync:synchronized block:^id(FMDatabase *db) {
        id<JRPersistent> result = [db jr_getByPrimaryKey:primaryKey clazz:clazz];
        EXE_BLOCK(complete, result);
        return result;
    }];
}

- (NSArray *)jr_getByConditions:(NSArray<JRQueryCondition *> *)conditions clazz:(Class<JRPersistent>)clazz groupBy:(NSString *)groupBy orderBy:(NSString *)orderBy limit:(NSString *)limit isDesc:(BOOL)isDesc {
    AssertRegisteredClazz(clazz);
    if (![self jr_checkExistsTable4Clazz:clazz]) {
        NSLog(@"table %@ doesn't exists", clazz);
        return @[];
    }
    JRSql *sql = [JRSqlGenerator sql4FindByConditions:conditions clazz:clazz groupBy:groupBy orderBy:orderBy limit:limit isDesc:isDesc table:nil];
    FMResultSet *ret = [self jr_executeQuery:sql];
    return [JRFMDBResultSetHandler handleResultSet:ret forClazz:clazz columns:nil];
}

- (NSArray<id<JRPersistent>> *)jr_getByConditions:(NSArray<JRQueryCondition *> *)conditions clazz:(Class<JRPersistent>)clazz groupBy:(NSString *)groupBy orderBy:(NSString *)orderBy limit:(NSString *)limit isDesc:(BOOL)isDesc synchronized:(BOOL)synchronized complete:(JRDBQueryComplete)complete {
    return
    [self jr_executeSync:synchronized block:^id(FMDatabase *db) {
        NSArray<id<JRPersistent>> *result = [db jr_getByConditions:conditions
                                                             clazz:clazz
                                                           groupBy:groupBy
                                                           orderBy:orderBy
                                                             limit:limit
                                                            isDesc:isDesc];
        EXE_BLOCK(complete, result);
        return result;
    }];
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
        
        NSMutableArray *subList = [NSMutableArray array];
        if ([obj class] == clazz) { // 父子关系 同个类
            NSString *condition = [NSString stringWithFormat:@"%@ = ?", ParentLinkColumn(key)];
            NSArray *array = [self jr_findByConditions:@[
                                                         [JRQueryCondition condition:condition args:@[[obj ID]] type:JRQueryConditionTypeAnd],
                                                         ]
                                                 clazz:clazz
                                               groupBy:nil
                                               orderBy:nil
                                                 limit:nil
                                                isDesc:NO
                                              useCache:NO];
            [subList addObjectsFromArray:array];
        } else {
            JRMiddleTable *mid = [JRMiddleTable table4Clazz:clazz andClazz:[obj class] db:self];
            NSArray *ids = [mid anotherClazzIDsWithID:[obj ID] clazz:[obj class]];
            
            [ids enumerateObjectsUsingBlock:^(id  _Nonnull aID, NSUInteger idx, BOOL * _Nonnull stop) {
                id sub = [self jr_findByID:aID clazz:clazz];
                if (sub) {
                    [subList addObject:sub];
                }
            }];
        }
        [obj setValue:subList forKey:key];
        
    }];
    
    return obj;
}

- (id<JRPersistent>)jr_findByID:(NSString *)ID clazz:(Class<JRPersistent>)clazz synchronized:(BOOL)synchronized useCache:(BOOL)useCache complete:(JRDBQueryComplete)complete {
    
    if (useCache) {
        id<JRPersistent> cacheObj = [self objInRecursiveCache:ID];
        if (cacheObj) {
            objc_setAssociatedObject(cacheObj, @selector(isCacheHit), @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            EXE_BLOCK(complete, cacheObj);
            return cacheObj;
        }
    }
    
    return
    [self jr_executeSync:synchronized block:^id(FMDatabase *db) {
        id<JRPersistent> result = [db jr_findByID:ID clazz:clazz];
        
        if (result) {[db saveObjInRecursiveCache:result];}
        
        EXE_BLOCK(complete, result);
        return result;
    }];
}

- (id<JRPersistent>)jr_findByPrimaryKey:(id)primaryKey clazz:(Class<JRPersistent>)clazz {
    if (![self jr_checkExistsTable4Clazz:clazz]) {
        NSLog(@"table %@ doesn't exists", clazz);
        return nil;
    }
    NSObject<JRPersistent> *obj = [self jr_getByPrimaryKey:primaryKey clazz:clazz];
    return [self jr_findByID:[obj ID] clazz:[obj class]];
}

- (id<JRPersistent>)jr_findByPrimaryKey:(id)primaryKey clazz:(Class<JRPersistent>)clazz synchronized:(BOOL)synchronized complete:(JRDBQueryComplete)complete {
    return
    [self jr_executeSync:synchronized block:^id(FMDatabase *db) {
        id<JRPersistent> result = [db jr_findByPrimaryKey:primaryKey clazz:clazz];
        EXE_BLOCK(complete, result);
        return result;
    }];
}

- (NSArray *)jr_findByConditions:(NSArray<JRQueryCondition *> *)conditions
                           clazz:(Class<JRPersistent>)clazz
                         groupBy:(NSString *)groupBy
                         orderBy:(NSString *)orderBy
                           limit:(NSString *)limit
                          isDesc:(BOOL)isDesc
                        useCache:(BOOL)useCache {

    NSArray<NSString *> *list = [self jr_getIDsByConditions:conditions
                                                      clazz:clazz
                                                    groupBy:groupBy
                                                    orderBy:orderBy
                                                      limit:limit
                                                     isDesc:isDesc];

    NSMutableArray *result = [NSMutableArray array];
    [list enumerateObjectsUsingBlock:^(NSString * ID, NSUInteger idx, BOOL * _Nonnull stop) {
        [result addObject:[self jr_findByID:ID clazz:clazz synchronized:NO useCache:useCache complete:nil]];
    }];
    
    return result;
}

- (NSArray<id<JRPersistent>> *)jr_findByConditions:(NSArray<JRQueryCondition *> *)conditions clazz:(Class<JRPersistent>)clazz groupBy:(NSString *)groupBy orderBy:(NSString *)orderBy limit:(NSString *)limit isDesc:(BOOL)isDesc synchronized:(BOOL)synchronized useCache:(BOOL)useCache complete:(JRDBQueryComplete)complete {
    return
    [self jr_executeSync:synchronized block:^id(FMDatabase *db) {
        NSArray<id<JRPersistent>> *result = [db jr_findByConditions:conditions
                                                              clazz:clazz
                                                            groupBy:groupBy
                                                            orderBy:orderBy
                                                              limit:limit
                                                             isDesc:isDesc
                                                           useCache:useCache];
        EXE_BLOCK(complete, result);
        return result;
    }];
}

#pragma mark - convenience method


- (long)jr_count4PrimaryKey:(id)pk clazz:(Class<JRPersistent>)clazz {
    NSAssert(pk, @"primary key should not be nil");
    FMResultSet *ret = [self jr_executeQuery:[JRSqlGenerator sql4CountByPrimaryKey:pk clazz:clazz table:nil]];
    while ([ret next]) {
        long count = [ret longForColumnIndex:0];
        [ret close];
        return count;
    }
    return 0;
}

- (long)jr_count4PrimaryKey:(id)pk clazz:(Class<JRPersistent>)clazz synchronized:(BOOL)synchronized complete:(JRDBQueryComplete)complete {
    return
    [[self jr_executeSync:synchronized block:^id(FMDatabase *db) {
        long result = [db jr_count4PrimaryKey:pk clazz:clazz];
        EXE_BLOCK(complete, @(result));
        return @(result);
    }] longValue];
}

- (long)jr_count4ID:(NSString *)ID clazz:(Class<JRPersistent>)clazz {
    NSAssert(ID, @"ID should not be nil");
    FMResultSet *ret = [self jr_executeQuery:[JRSqlGenerator sql4CountByID:ID clazz:clazz table:nil]];
    while ([ret next]) {
        return [ret longForColumnIndex:0];
    }
    return 0;
}

- (long)jr_count4ID:(NSString *)ID clazz:(Class<JRPersistent>)clazz synchronized:(BOOL)synchronized complete:(JRDBQueryComplete)complete {
    return
    [[self jr_executeSync:synchronized block:^id(FMDatabase *db) {
        long result = [db jr_count4ID:ID clazz:clazz];
        EXE_BLOCK(complete, @(result));
        return @(result);
    }] longValue];
}

- (NSArray<NSString *> * _Nonnull)jr_getIDsByConditions:(NSArray<JRQueryCondition *> * _Nullable)conditions
                                                  clazz:(Class<JRPersistent> _Nonnull)clazz
                                                groupBy:(NSString * _Nullable)groupBy
                                                orderBy:(NSString * _Nullable)orderBy
                                                  limit:(NSString * _Nullable)limit
                                                 isDesc:(BOOL)isDesc {
    JRSql *sql = [JRSqlGenerator sql4GetColumns:nil byConditions:conditions clazz:clazz groupBy:groupBy orderBy:orderBy limit:limit isDesc:isDesc table:nil];
    FMResultSet *resultset = [self jr_executeQuery:sql];
    NSMutableArray *array = [NSMutableArray array];
    while ([resultset next]) {
        [array addObject:[resultset stringForColumn:@"_id"]];
    }
    [resultset close];
    return array;
}

- (NSArray<NSString *> *)jr_getIDsByConditions:(NSArray<JRQueryCondition *> *)conditions clazz:(Class<JRPersistent>)clazz groupBy:(NSString *)groupBy orderBy:(NSString *)orderBy limit:(NSString *)limit isDesc:(BOOL)isDesc synchronized:(BOOL)synchronized complete:(JRDBQueryComplete)complete {
    return
    [self jr_executeSync:synchronized block:^id(FMDatabase *db) {
        NSArray<NSString *> *result = [db jr_getIDsByConditions:conditions
                                                          clazz:clazz
                                                        groupBy:groupBy
                                                        orderBy:orderBy
                                                          limit:limit
                                                         isDesc:isDesc];
        EXE_BLOCK(complete, result);
        return result;
    }];
}

@end

#pragma mark - cache

@implementation FMDatabase (JRDBCache)

- (void)saveObjInRecursiveCache:(id<JRPersistent>)obj {
    NSMutableDictionary *cache = [[JRDBMgr shareInstance] recursiveCacheForDBPath:self.databasePath];
    cache[[obj ID]] = obj;
}

- (void)saveObjInUnRecursiveCache:(id<JRPersistent>)obj {
    NSMutableDictionary *cache = [[JRDBMgr shareInstance] unRecursiveCacheForDBPath:self.databasePath];
    cache[[obj ID]] = obj;
}

- (void)removeObjInRecursiveCache:(NSString *)ID {
    NSMutableDictionary *cache = [[JRDBMgr shareInstance] recursiveCacheForDBPath:self.databasePath];
    [cache removeObjectForKey:ID];
}

- (void)removeObjInUnRecursiveCache:(NSString *)ID {
    NSMutableDictionary *cache = [[JRDBMgr shareInstance] unRecursiveCacheForDBPath:self.databasePath];
    [cache removeObjectForKey:ID];
}

- (id<JRPersistent>)objInRecursiveCache:(NSString *)ID {
    NSMutableDictionary *cache = [[JRDBMgr shareInstance] recursiveCacheForDBPath:self.databasePath];
    return cache[ID];
}

- (id<JRPersistent>)objInUnRecursiveCache:(NSString *)ID {
    NSMutableDictionary *cache = [[JRDBMgr shareInstance] unRecursiveCacheForDBPath:self.databasePath];
    return cache[ID];
}

@end


@implementation FMDatabase (JRSql)

- (NSArray<id<JRPersistent>> *)jr_getByJRSql:(JRSql *)sql sync:(BOOL)sync resultClazz:(Class<JRPersistent>)clazz columns:(NSArray *)columns {
    return [self jr_executeSync:sync block:^id _Nullable(FMDatabase * _Nonnull db) {
        FMResultSet *restultSet = [db jr_executeQuery:sql];
        NSArray *array = [JRFMDBResultSetHandler handleResultSet:restultSet forClazz:clazz columns:columns];
        return array;
    }];
}

- (NSArray<id<JRPersistent>> *)jr_findByJRSql:(JRSql *)sql sync:(BOOL)sync resultClazz:(Class<JRPersistent>)clazz columns:(NSArray *)columns {
    return [self jr_executeSync:sync block:^id _Nullable(FMDatabase * _Nonnull db) {
        FMResultSet *restultSet = [db jr_executeQuery:sql];
        NSArray *array = [JRFMDBResultSetHandler handleResultSet:restultSet forClazz:clazz columns:columns];
        if (!columns.count) {
            NSMutableArray *arr = [NSMutableArray array];
            [array enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                [arr addObject:[db jr_findByID:[obj ID] clazz:clazz]];
            }];
            array = [arr copy];
        }
        return array;
    }];
}

@end



