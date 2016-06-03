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
    [[self databaseQueue] close];
    objc_setAssociatedObject(self, &queuekey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (FMDatabaseQueue *)databaseQueue {
    FMDatabaseQueue *q = objc_getAssociatedObject(self, &queuekey);
    if (!q) {
        q = [FMDatabaseQueue databaseQueueWithPath:self.databasePath];
        objc_setAssociatedObject(self, &queuekey, q, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return q;
}

- (void)inQueue:(void (^)(FMDatabase *))block {
    [[self databaseQueue] inDatabase:^(FMDatabase *db) {
        EXE_BLOCK(block, db);
    }];
}

- (BOOL)inTransaction:(void (^)(FMDatabase *, BOOL *))block {
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
//    [[self databaseQueue] inTransaction:^(FMDatabase *db, BOOL *rollback) {
//        EXE_BLOCK(block, db, rollback);
//    }];
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

#pragma mark - table message

- (NSArray<JRColumnSchema *> *)schemasInClazz:(Class<JRPersistent>)clazz {
    FMResultSet *ret = [[JRDBMgr defaultDB] getTableSchema:[JRReflectUtil shortClazzName:clazz]];
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

#pragma mark - data operation

/**
 *  保存单条，不关联保存
 */
- (BOOL)save:(id<JRPersistent>)obj {
    if ([[obj class] jr_customPrimarykey]) { // 自定义主键
        NSAssert([obj jr_customPrimarykeyValue] != nil, @"custom Primary key should not be nil");
        NSObject *old = (NSObject *)[self getByPrimaryKey:[obj jr_customPrimarykeyValue] clazz:[obj class]];
        NSAssert(!old, @"primary key is exists");
    } else { // 默认主键
        NSAssert(obj.ID == nil, @"The obj:%@ to be saved should not hold a primary key", obj);
    }
    
    NSArray *args;
    NSString *sql = [JRSqlGenerator sql4Insert:obj args:&args toDB:self];
    [obj setID:uuid()];
    args = [@[obj.ID] arrayByAddingObjectsFromArray:args];
    BOOL ret = [self executeUpdate:sql withArgumentsInArray:args];
    
    // 保存完，执行block
    [obj jr_executeFinishBlocks];
    
    return ret;
}


- (BOOL)handleSave:(id<JRPersistent>)obj stack:(NSMutableArray<id<JRPersistent>> **)stack needRollBack:(BOOL *)needRollBack {
    
    if (*needRollBack) {
        return NO;
    }
    
    [[[obj class] jr_singleLinkedPropertyNames] enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, Class<JRPersistent>  _Nonnull clazz, BOOL * _Nonnull stop) {
        id value = [((NSObject *)obj) valueForKey:key];
        if (value) {
            NSString *identifier = uuid();
            if ([*stack containsObject:value]) {
                [value jr_addDidFinishBlock:^(id<JRPersistent>  _Nonnull object) {
                    [((NSObject *)obj) jr_updateWithColumn:nil];
                    [object jr_removeDidFinishBlockForIdentifier:identifier];
                } forIdentifier:identifier];
            } else {
                if (![*stack containsObject:obj]) {
                    [*stack addObject:obj];
                }
                [obj jr_addDidFinishBlock:^(id<JRPersistent>  _Nonnull object) {
                    [*stack removeObject:object];
                    [object jr_removeDidFinishBlockForIdentifier:identifier];
                } forIdentifier:identifier];
                [self handleSave:value stack:stack needRollBack:needRollBack];
            }
        }
    }];
    
    NSString *tableName = [JRReflectUtil shortClazzName:[obj class]];
    if (![self tableExists:tableName]) {
        NSAssert([self createTable4Clazz:[obj class]], @"create table: %@ error", tableName);
    }
    
//    if (!hierarchy || ![obj jr_primaryKeyValue]) {
    if (![obj jr_primaryKeyValue]) {
        BOOL ret = [self save:obj];
        *needRollBack = !ret;
        return ret;
    } else {
        if (![obj ID]) {
            [obj setID:[[self getByPrimaryKey:[obj jr_primaryKeyValue] clazz:[obj class]] ID]];
        }
        // 子对象已经存在不用保存，直接返回，若需要更新，需要自行手动更新
        return YES;
    }
    
}

- (BOOL)saveObj:(id<JRPersistent>)obj {
    NSAssert([self inTransaction], @"save operation can occur an error, you should use 'inTransaction:' method to save");
    NSMutableArray *stack = [NSMutableArray array];
    BOOL needRollBack = NO;
    [self handleSave:obj stack:&stack needRollBack:&needRollBack];
    if (needRollBack) { [self rollback]; }
    return !needRollBack;
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
        id<JRPersistent> old = [self getByPrimaryKey:[obj jr_customPrimarykeyValue] clazz:[obj class]];;
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
    // 保存完，执行block
    [obj jr_executeFinishBlocks];
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
    BOOL ret = [self executeUpdate:sql withArgumentsInArray:@[[obj jr_primaryKeyValue]]];
    // 保存完，执行block
    [obj jr_executeFinishBlocks];
    return ret;
}

- (void)deleteObj:(id<JRPersistent>)obj complete:(JRDBComplete)complete {
    [self inQueue:^(FMDatabase *db) {
        EXE_BLOCK(complete, [db deleteObj:obj]);
    }];
}

- (BOOL)deleteAll:(Class<JRPersistent> _Nonnull)clazz {
    if (![self checkExistsTable4Clazz:clazz]) {
        NSLog(@"table : %@ doesn't exists", clazz);
        return NO;
    }
    NSString *sql = [JRSqlGenerator sql4DeleteAll:clazz];
    BOOL ret = [self executeUpdate:sql withArgumentsInArray:nil];
    return ret;
}

- (void)deleteAll:(Class<JRPersistent> _Nonnull)clazz complete:(JRDBComplete _Nullable)complete {
    [self inQueue:^(FMDatabase * _Nonnull db) {
        EXE_BLOCK(complete, [db deleteAll:clazz]);
    }];
}


#pragma mark - single level query operation

- (id<JRPersistent>)getByID:(NSString *)ID clazz:(Class<JRPersistent>)clazz {
    NSAssert(ID, @"id should be nil");
    NSString *sql = [JRSqlGenerator sql4GetByIDWithClazz:clazz];
    FMResultSet *ret = [self executeQuery:sql withArgumentsInArray:@[ID]];
    return [JRFMDBResultSetHandler handleResultSet:ret forClazz:clazz].firstObject;
}

- (id<JRPersistent>)getByPrimaryKey:(id)primaryKey clazz:(Class<JRPersistent>)clazz {
    NSAssert(primaryKey, @"id should be nil");
    NSString *sql = [JRSqlGenerator sql4GetByPrimaryKeyWithClazz:clazz];
    FMResultSet *ret = [self executeQuery:sql withArgumentsInArray:@[primaryKey]];
    return [JRFMDBResultSetHandler handleResultSet:ret forClazz:clazz].firstObject;
}

- (NSArray *)getAll:(Class<JRPersistent>)clazz orderBy:(NSString *)orderby isDesc:(BOOL)isDesc {
    if (![self checkExistsTable4Clazz:clazz]) {
        NSLog(@"table %@ doesn't exists", clazz);
        return @[];
    }
    NSString *sql = [JRSqlGenerator sql4FindAll:clazz orderby:orderby isDesc:isDesc];
    FMResultSet *ret = [self executeQuery:sql];
    return [JRFMDBResultSetHandler handleResultSet:ret forClazz:clazz];
}

- (NSArray *)getByConditions:(NSArray<JRQueryCondition *> *)conditions clazz:(Class<JRPersistent>)clazz groupBy:(NSString *)groupBy orderBy:(NSString *)orderBy limit:(NSString *)limit isDesc:(BOOL)isDesc {
    if (![self checkExistsTable4Clazz:clazz]) {
        NSLog(@"table %@ doesn't exists", clazz);
        return @[];
    }
    NSArray *args = nil;
    NSString *sql = [JRSqlGenerator sql4FindByConditions:conditions clazz:clazz groupBy:groupBy orderBy:orderBy limit:limit isDesc:isDesc args:&args];
    FMResultSet *ret = [self executeQuery:sql withArgumentsInArray:args];
    return [JRFMDBResultSetHandler handleResultSet:ret forClazz:clazz];
}

#pragma mark - multi level query operation

- (id<JRPersistent>)objInStack:(NSArray *)array withID:(NSString *)ID {
    __block id<JRPersistent> obj = nil;
    [array enumerateObjectsUsingBlock:^(id<JRPersistent>  _Nonnull stackObj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([ID isEqualToString:[stackObj ID]]) {
            obj = stackObj;
            *stop = YES;
        }
    }];
    return obj;
}

- (id<JRPersistent>)handleSingleLinkFindByID:(NSString *)ID clazz:(Class<JRPersistent>)clazz stack:(NSMutableArray<id<JRPersistent>> **)stack{
    id obj = [self getByID:ID clazz:clazz];
    [[clazz jr_singleLinkedPropertyNames] enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, Class<JRPersistent>  _Nonnull subClazz, BOOL * _Nonnull stop) {
        NSString *subID = [((NSObject *)obj) singleLinkIDforKey:key];
        if (subID) {
            [(*stack) addObject:obj];
            id<JRPersistent> exists = [self objInStack:(*stack) withID:subID];
            if (!exists) {
                exists = [self handleSingleLinkFindByID:subID clazz:subClazz stack:stack];
            }
            [obj setValue:exists forKey:key];
        }
    }];
    return obj;
}

- (id<JRPersistent>)findByID:(NSString *)ID clazz:(Class<JRPersistent>)clazz {
    NSMutableArray *array = [NSMutableArray array];
    return [self handleSingleLinkFindByID:ID clazz:clazz stack:&array];
}

- (id<JRPersistent>)findByPrimaryKey:(id)primaryKey clazz:(Class<JRPersistent>)clazz {
    NSAssert([self checkExistsTable4Clazz:clazz], @"table %@ doesn't exists", clazz);
    id<JRPersistent> obj = [self getByPrimaryKey:primaryKey clazz:clazz];
    NSMutableArray *array = [NSMutableArray array];
    return [self handleSingleLinkFindByID:[obj ID] clazz:clazz stack:&array];
}


- (NSArray *)findAll:(Class<JRPersistent>)clazz {
    return [self findAll:clazz orderBy:nil isDesc:NO];
}

- (NSArray *)findAll:(Class<JRPersistent>)clazz orderBy:(NSString *)orderby isDesc:(BOOL)isDesc {
    NSArray *list = [self getAll:clazz orderBy:orderby isDesc:isDesc];
    NSMutableArray *result = [NSMutableArray array];
    [list enumerateObjectsUsingBlock:^(id<JRPersistent>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSMutableArray *array = [NSMutableArray array];
        [result addObject:[self handleSingleLinkFindByID:[obj ID] clazz:[obj class] stack:&array]];
    }];
    return result;
}

- (NSArray *)findByConditions:(NSArray<JRQueryCondition *> *)conditions clazz:(Class<JRPersistent>)clazz groupBy:(NSString *)groupBy orderBy:(NSString *)orderBy limit:(NSString *)limit isDesc:(BOOL)isDesc {
    NSArray<id<JRPersistent>> *list = [self getByConditions:conditions clazz:clazz groupBy:groupBy orderBy:orderBy limit:limit isDesc:isDesc];
    NSMutableArray *result = [NSMutableArray array];
    [list enumerateObjectsUsingBlock:^(id<JRPersistent>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSMutableArray *array = [NSMutableArray array];
        [result addObject:[self handleSingleLinkFindByID:[obj ID] clazz:[obj class] stack:&array]];
    }];
    return result;
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


