//
//  NSObject+JRDB.m
//  JRDB
//
//  Created by JMacMini on 16/5/10.
//  Copyright © 2016年 Jrwong. All rights reserved.
//

#import "NSObject+JRDB.h"
#import <objc/runtime.h>
#import "FMDatabase+JRDB.h"
#import "JRDBMgr.h"
#import "JRFMDBResultSetHandler.h"

#define JR_DEFAULTDB [JRDBMgr defaultDB]

const NSString *JRDB_IDKEY = @"JRDB_IDKEY";

@implementation NSObject (JRDB)

- (void)setID:(NSString *)ID {
    objc_setAssociatedObject(self, &JRDB_IDKEY, ID, OBJC_ASSOCIATION_COPY_NONATOMIC);
}
- (NSString *)ID {
    return objc_getAssociatedObject(self, &JRDB_IDKEY);
}
+ (NSArray *)jr_excludePropertyNames {
    return @[];
}

+ (NSDictionary *)jr_mapPropNames {
    return @{};
}

#pragma mark - save
- (BOOL)jr_saveToDB:(FMDatabase *)db {
    return [db saveObj:self];
}

- (void)jr_saveToDB:(FMDatabase *)db complete:(JRDBComplete)complete {
    [db saveObj:self complete:^(BOOL success) {
        EXE_BLOCK(complete, success);
    }];
}

- (BOOL)jr_save {
    return [self jr_saveToDB:JR_DEFAULTDB];
}

- (void)jr_saveWithComplete:(JRDBComplete)complete {
    [self jr_saveToDB:JR_DEFAULTDB complete:complete];
}

#pragma mark - update
- (BOOL)jr_updateToDB:(FMDatabase *)db column:(NSArray *)columns {
    return [db updateObj:self columns:columns];
}
- (void)jr_updateToDB:(FMDatabase *)db column:(NSArray *)columns complete:(JRDBComplete)complete {
    [db updateObj:self columns:columns complete:^(BOOL success) {
        EXE_BLOCK(complete, success);
    }];
}

- (BOOL)jr_updateWithColumn:(NSArray *)columns {
    return [self jr_updateToDB:JR_DEFAULTDB column:columns];
}

- (void)jr_updateWithColumn:(NSArray *)columns Complete:(JRDBComplete)complete {
    [self jr_updateToDB:JR_DEFAULTDB column:columns complete:complete];
}

#pragma mark - delete

- (BOOL)jr_deleteFromDB:(FMDatabase *)db {
    return [db deleteObj:self];
}

- (void)jr_deleteFromDB:(FMDatabase *)db complete:(JRDBComplete)complete {
    [db deleteObj:self complete:^(BOOL success) {
        EXE_BLOCK(complete, success);
    }];
}

- (BOOL)jr_delete {
    return [self jr_deleteFromDB:JR_DEFAULTDB];
}

- (void)jr_deleteWithComplete:(JRDBComplete)complete {
    [self jr_deleteFromDB:JR_DEFAULTDB complete:complete];
}

#pragma mark - select

+ (instancetype)jr_findByID:(NSString *)ID fromDB:(FMDatabase *)db {
    return [db findByID:ID clazz:[self class]];
}

+ (instancetype)jr_findByID:(NSString *)ID {
    return [self jr_findByID:ID fromDB:JR_DEFAULTDB];
}

+ (NSArray<id<JRPersistent>> *)jr_findAllFromDB:(FMDatabase *)db {
    return [db findAll:[self class]];
}
+ (NSArray<id<JRPersistent>> *)jr_findAll {
    return [self jr_findAllFromDB:JR_DEFAULTDB];
}

+ (NSArray<id<JRPersistent>> *)jr_findAllFromDB:(FMDatabase *)db orderBy:(NSString *)orderBy isDesc:(BOOL)isDesc {
    return [db findAll:[self class] orderBy:orderBy isDesc:isDesc];
}
+ (NSArray<id<JRPersistent>> *)jr_findAllOrderBy:(NSString *)orderBy isDesc:(BOOL)isDesc {
    return [self jr_findAllFromDB:JR_DEFAULTDB orderBy:orderBy isDesc:isDesc];
}

+ (NSArray<id<JRPersistent>> *)jr_findByConditions:(NSArray<JRQueryCondition *> *)conditions groupBy:(NSString *)groupBy orderBy:(NSString *)orderBy limit:(NSString *)limit isDesc:(BOOL)isDesc fromDB:(FMDatabase *)db {
    return [db findByConditions:conditions clazz:[self class] groupBy:groupBy orderBy:orderBy limit:limit isDesc:isDesc];
}

+ (NSArray<id<JRPersistent>> *)jr_findByConditions:(NSArray<JRQueryCondition *> *)conditions groupBy:(NSString *)groupBy orderBy:(NSString *)orderBy limit:(NSString *)limit isDesc:(BOOL)isDesc {
    return [self jr_findByConditions:conditions groupBy:groupBy orderBy:orderBy limit:limit isDesc:isDesc fromDB:JR_DEFAULTDB];
}

#pragma mark - sql
+ (NSArray<id<JRPersistent>> *)jr_executeSql:(NSString *)sql args:(NSArray *)args fromDB:(FMDatabase *)db {
    FMResultSet *ret = [db executeQuery:sql withArgumentsInArray:args];
    return [JRFMDBResultSetHandler handleResultSet:ret forClazz:[self class]];
}

+ (NSArray<id<JRPersistent>> *)jr_executeSql:(NSString *)sql args:(NSArray *)args {
    return [self jr_executeSql:sql args:args fromDB:JR_DEFAULTDB];
}

+ (NSUInteger)jr_countForSql:(NSString *)sql args:(NSArray *)args fromDB:(FMDatabase *)db {
    FMResultSet *ret = [db executeQuery:sql withArgumentsInArray:args];
    return (NSUInteger)[ret unsignedLongLongIntForColumnIndex:0];
}

+ (NSUInteger)jr_countForSql:(NSString *)sql args:(NSArray *)args {
    return [self jr_countForSql:sql args:args fromDB:JR_DEFAULTDB];
}

#pragma mark - table operation

+ (BOOL)jr_createTableInDB:(FMDatabase *)db {
    return [db createTable4Clazz:[self class]];
}

+ (BOOL)jr_createTable {
    return [self jr_createTableInDB:JR_DEFAULTDB];
}

+ (BOOL)jr_updateTableInDB:(FMDatabase *)db {
    return [db updateTable4Clazz:[self class]];
}

+ (BOOL)jr_updateTable {
    return [self jr_updateTableInDB:JR_DEFAULTDB];
}

+ (BOOL)jr_dropTableInDB:(FMDatabase *)db {
    return [db dropTable4Clazz:[self class]];
}

+ (BOOL)jr_dropTable {
    return [self jr_dropTableInDB:JR_DEFAULTDB];
}

+ (BOOL)jr_truncateTableInDB:(FMDatabase *)db {
    return [db truncateTable4Clazz:[self class]];
}

+ (BOOL)jr_truncateTable {
    return [self jr_truncateTableInDB:JR_DEFAULTDB];
}


@end
