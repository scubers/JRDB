//
//  JRMiddleTable.m
//  JRDB
//
//  Created by JMacMini on 16/6/6.
//  Copyright © 2016年 Jrwong. All rights reserved.
//

#import "JRMiddleTable.h"
#import "NSObject+Reflect.h"
#import "FMDatabase+JRPersistentHandler.h"

#define MiddleTableName(clazz1,clazz2) [NSString stringWithFormat:@"%@_%@_Mid_Table", [clazz1 jr_tableName],[clazz2 jr_tableName]]
#define MiddleColumn4Clazz(clazz) [NSString stringWithFormat:@"%@_ids", [clazz jr_tableName]]


@implementation JRMiddleTable

+ (instancetype)table4Clazz:(Class<JRPersistent>)clazz1 andClazz:(Class<JRPersistent>)clazz2 db:(id<JRPersistentHandler>)db {
    JRMiddleTable *t = [JRMiddleTable new];
    t->_db = db;
    t->_clazz1 = clazz1;
    t->_clazz2 = clazz2;
    return t;
}

- (NSString *)tableName {
    if ([_db jr_tableExists:MiddleTableName(_clazz1, _clazz2)]) {
        return MiddleTableName(_clazz1, _clazz2);
    }
    return MiddleTableName(_clazz2, _clazz1);
}

- (BOOL)saveIDs:(NSArray<NSString *> *)IDs withClazz:(Class<JRPersistent>)withClazz forID:(NSString *)ID withIDClazz:(Class<JRPersistent>)IDClazz {

    NSAssert([_db jr_isTransactioning], @"should in a transaction");
    
    if (![_db jr_tableExists:[self tableName]]) {
        // TODO: createTable
        if (![self _createTable]) {
            return NO;
        }
    }
    
    // TODO: 把之前的关系全删了
    BOOL ret = [self deleteID:ID forClazz:IDClazz];
    if (!ret) { return NO; }
    
    if (!IDs.count) {
        return YES;
    }
    
    NSArray<NSString *> *exisisIDs = [self anotherClazzIDsWithID:ID clazz:IDClazz];
    NSMutableArray *array = [NSMutableArray array];
    [IDs enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (![exisisIDs containsObject:obj]) {
            [array addObject:obj];
        }
    }];
    
    // 保存
    __block BOOL flag = YES;
    [array enumerateObjectsUsingBlock:^(NSString * _Nonnull aID, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *sql = [NSString stringWithFormat:@"insert into %@ (%@, %@) values(?, ?)", [self tableName], MiddleColumn4Clazz(withClazz), MiddleColumn4Clazz(IDClazz)];
        flag = [_db jr_executeUpdate:sql params:@[aID, ID]];
        *stop = !flag;
    }];
    return flag;
}

- (NSArray<NSString *> *)anotherClazzIDsWithID:(NSString *)ID clazz:(Class<JRPersistent>)clazz {
    if (![_db jr_tableExists:[self tableName]]) {
        return @[];
    }
    // TODO: 查询
    NSString *sql = [NSString stringWithFormat:@"select * from %@ where %@ = ?", [self tableName], MiddleColumn4Clazz(clazz)];
    FMResultSet *resultSet = [_db jr_executeQuery:sql params:@[ID]];
    
    NSMutableArray *array = [NSMutableArray array];
    while ([resultSet next]) {
        [array addObject:[resultSet stringForColumn:MiddleColumn4Clazz([self anotherClazz:clazz])]];
    }
    return array;
}

- (Class)anotherClazz:(Class)clazz {
    return clazz == _clazz1 ? _clazz2 : _clazz1;
}

- (BOOL)saveObjs:(NSArray<id<JRPersistent>> *)objs forObj:(id<JRPersistent>)obj {
//    if (!objs.count) {
//        return YES;
//    }
    NSMutableArray *ids = [NSMutableArray array];
    [objs enumerateObjectsUsingBlock:^(id<JRPersistent>  _Nonnull object, NSUInteger idx, BOOL * _Nonnull stop) {
        [ids addObject:[object ID]];
    }];
    return [self saveIDs:ids withClazz:[objs.firstObject class] forID:[obj ID] withIDClazz:[obj class]];
}

- (BOOL)deleteID:(NSString *)ID forClazz:(Class<JRPersistent>)clazz {
    if (![_db jr_tableExists:[self tableName]]) { return YES; }
    NSString *sql = [NSString stringWithFormat:@"delete from %@ where %@ = ?;", [self tableName], MiddleColumn4Clazz(clazz)];
    return [_db jr_executeUpdate:sql params:@[ID]];
}

- (BOOL)cleanRubbishData {
    //delete from Person_money_mid_table where (person_ids not in (select _id from Person)) or (money_ids not in (select _id from Money))
    return
    
    [_db jr_inTransaction:^(FMDatabase * _Nonnull db, BOOL * _Nonnull rollBack) {
        NSString *sql =
        [NSString stringWithFormat:@"delete from %@ where (%@ not in (select %@ from %@)) or (%@ not in (select %@ from %@))"
         , [self tableName]
         , MiddleColumn4Clazz(_clazz1)
         , DBIDKey
         , [_clazz1 jr_tableName]
         , MiddleColumn4Clazz(_clazz2)
         , DBIDKey
         , [_clazz2 jr_tableName]];
        
        *rollBack = ![db executeUpdate:sql];
    }];
    
}

#pragma mark - Private Method
- (BOOL)_createTable {
    NSString *sql = [NSString stringWithFormat:@"create table if not exists %@ (%@ TEXT, %@ TEXT)", [self tableName], MiddleColumn4Clazz(_clazz1), MiddleColumn4Clazz(_clazz2)];
    return [_db jr_executeUpdate:sql params:nil];
}

@end
