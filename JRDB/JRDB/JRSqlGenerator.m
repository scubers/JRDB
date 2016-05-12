//
//  JRSqlGenerator.m
//  JRDB
//
//  Created by JMacMini on 16/5/10.
//  Copyright © 2016年 Jrwong. All rights reserved.
//

#import "JRSqlGenerator.h"
#import "JRReflectUtil.h"
#import "NSObject+JRDB.h"
//#import "FMDB.h"
#import "JRQueryCondition.h"

@import FMDB;

@implementation JRSqlGenerator

+ (NSString *)createTableSql4Clazz:(Class<JRPersistent>)clazz {
    NSMutableString *sql = [NSMutableString string];
    // create table 'tableName' (ID text primary key, 'p1' 'type1')
    NSString *tableName = [JRReflectUtil shortClazzName:clazz];
    [sql appendFormat:@"create table %@ (_ID text primary key ", tableName];
    
    NSDictionary *dict = [JRReflectUtil ivarAndEncode4Clazz:clazz];
    NSArray *excludes = [clazz jr_excludePropertyNames];
    
    for (NSString *name in dict.allKeys) {
        if ([excludes containsObject:name] || isID(name)) {
            continue;
        }
        NSString *type = [self typeWithEncodeName:dict[name]];
        if (!type) {
            continue;
        }
        [sql appendFormat:@", %@ %@", name, type];
    }
    [sql appendString:@");"];
    NSLog(@"sql: %@", sql);
    return sql;
}

+ (NSArray<NSString *> *)updateTableSql4Clazz:(Class<JRPersistent>)clazz inDB:(FMDatabase *)db {
    NSString *tableName = [JRReflectUtil shortClazzName:clazz];
    if (![db tableExists:tableName]) {
        return @[[self createTableSql4Clazz:clazz]];
    }
    
    NSMutableArray *sqls = [NSMutableArray array];
    
    NSDictionary *dict = [JRReflectUtil ivarAndEncode4Clazz:clazz];
    NSArray *excludes = [clazz jr_excludePropertyNames];
    // alter 'tableName' add 'name' 'type';
    BOOL flag = NO;
    for (NSString *name in dict.allKeys) {
        if (![db columnExists:name inTableWithName:tableName] && ![excludes containsObject:name]
            ) {
            NSString *type = [self typeWithEncodeName:dict[name]];
            if (!type) {
                continue;
            }
            [sqls addObject:[NSString stringWithFormat:@"alter table %@ add column %@ %@ ;", tableName, name, type]];
            
            flag = YES;
        }
    }
    NSLog(@"sqls: %@", sqls);
    return sqls;
}

+ (NSString *)deleteTableSql4Clazz:(Class<JRPersistent>)clazz{
    NSString *sql = [NSString stringWithFormat:@"drop table %@", [JRReflectUtil shortClazzName:clazz]];
    NSLog(@"sql: %@", sql);
    return sql;
}

+ (NSString *)dropTableSql4Clazz:(Class<JRPersistent>)clazz {
    NSString *sql = [NSString stringWithFormat:@"drop table %@ ;",[JRReflectUtil shortClazzName:clazz]];
    NSLog(@"sql: %@", sql);
    return sql;
}

+ (NSString *)sql4Insert:(id<JRPersistent>)obj args:(NSArray *__autoreleasing *)args{
    NSMutableArray *argsList = [NSMutableArray array];
    
    NSMutableString *sql = [NSMutableString string];
    NSString *tableName = [JRReflectUtil shortClazzName:[obj class]];
    [sql appendFormat:@" insert into %@ ('_ID', ", tableName];
    // insert into tablename (_ID) values (?)
    
    NSMutableString *sql2 = [NSMutableString string];
    [sql2 appendFormat:@"values ( ? ,"];
    
    NSDictionary *dict = [JRReflectUtil ivarAndEncode4Clazz:[obj class]];
    NSArray *excludes = [[obj class] jr_excludePropertyNames];
    
    for (NSString *name in dict.allKeys) {
        if ([excludes containsObject:name] || isID(name)) {
            continue;
        }
        [sql appendFormat:@" %@ ", name];
        [sql2 appendFormat:@" ? "];
        id value = [(NSObject *)obj valueForKey:name];
        if (!value) {
            value = [NSNull null];
        }
        [argsList addObject:value];
        
        [sql appendString:@","];
        [sql2 appendString:@","];
    }
    
    if ([sql hasSuffix:@","]) {
        sql = [[sql substringToIndex:sql.length - 1] mutableCopy];
    }
    if ([sql2 hasSuffix:@","]) {
        sql2 = [[sql2 substringToIndex:sql2.length - 1] mutableCopy];
    }
    
    [sql appendString:@")"];
    [sql2 appendString:@");"];
    [sql appendString:sql2];
    *args = argsList;
    NSLog(@"sql: %@", sql);
    return sql;
}

+ (NSString *)sql4Delete:(id<JRPersistent>)obj {
    NSString *sql = [NSString stringWithFormat:@"delete from %@ where _ID = ? ;", [JRReflectUtil shortClazzName:[obj class]]];
    NSLog(@"sql: %@", sql);
    return sql;
}

+ (NSString *)sql4Update:(id<JRPersistent>)obj columns:(NSArray<NSString *> *)columns args:(NSArray *__autoreleasing *)args {
    NSMutableArray *argsList = [NSMutableArray array];
    NSMutableString *sql = [NSMutableString string];
    NSString *tableName = [JRReflectUtil shortClazzName:[obj class]];
    [sql appendFormat:@" update %@ set ", tableName];
    
    NSDictionary *dict = [JRReflectUtil ivarAndEncode4Clazz:[obj class]];
    NSArray *excludes = [[obj class] jr_excludePropertyNames];
    
    for (NSString *name in dict.allKeys) {
        if ([excludes containsObject:name] || isID(name)) {
            continue;
        }
        if (columns.count && ![columns containsObject:name]) {
            continue;
        }
        [sql appendFormat:@" %@ = ? ", name];
        id value = [(NSObject *)obj valueForKey:name];
        if (!value) {
            value = [NSNull null];
        }
        [argsList addObject:value];
        
        [sql appendString:@","];
    }
    if ([sql hasSuffix:@","]) {
        sql = [[sql substringToIndex:sql.length - 1] mutableCopy];
    }
    [sql appendString:@" where _ID = ? ;"];
    *args = argsList;
    NSLog(@"sql: %@", sql);
    return sql;
}

+ (NSString *)sql4GetByIdWithClazz:(Class<JRPersistent>)clazz {
    NSString *sql = [NSString stringWithFormat:@"select * from %@ where _ID = ?;", [JRReflectUtil shortClazzName:clazz]];
    NSLog(@"sql: %@", sql);
    return sql;
}

+ (NSString *)sql4FindAll:(Class<JRPersistent>)clazz orderby:(NSString *)orderby isDesc:(BOOL)isDesc {
    NSString *sql = [NSString stringWithFormat:@"select * from %@ ", [JRReflectUtil shortClazzName:clazz]];
    if (orderby.length) {
        sql = [sql stringByAppendingFormat:@" order by %@ ", orderby.length ? orderby : @"_ID"];
    }
    sql = [sql stringByAppendingFormat:@" %@ ;", isDesc ? @"desc" : @""];
    NSLog(@"sql: %@", sql);
    return sql;
}

+ (NSString *)sql4FindByConditions:(NSArray<JRQueryCondition *> *)conditions clazz:(Class<JRPersistent>)clazz groupBy:(NSString *)groupBy orderBy:(NSString *)orderBy limit:(NSString *)limit isDesc:(BOOL)isDesc {
    NSMutableString *sql = [NSMutableString string];
    [sql appendFormat:@" select * from %@ where 1=1 ", [JRReflectUtil shortClazzName:clazz]];
    
    for (JRQueryCondition *condition in conditions) {
        [sql appendFormat:@" %@ %@ ", condition.type == JRQueryConditionTypeAnd ? @"and" : @"or", condition.condition];
    }
    
    if (groupBy.length) {
        [sql appendFormat:@" group by %@ ", groupBy];
    }
    
    [sql appendFormat:@" order by %@ ", orderBy.length ? orderBy : @"_ID"];
    
    [sql appendFormat:@" %@ ", isDesc? @"desc" : @""];
    
    if (limit.length) {
        [sql appendFormat:@" %@ ", limit];
    }
    
    [sql appendString:@" ; "];
    
    NSLog(@"sql: %@", sql);
    return sql;
}

+ (NSString *)typeWithEncodeName:(NSString *)encode {
    if ([encode isEqualToString:[NSString stringWithUTF8String:@encode(int)]]
        ||[encode isEqualToString:[NSString stringWithUTF8String:@encode(unsigned int)]]
        ||[encode isEqualToString:[NSString stringWithUTF8String:@encode(long)]]
        ||[encode isEqualToString:[NSString stringWithUTF8String:@encode(unsigned long)]]
        ) {
        return @"INTEGER";
    }
    if ([encode isEqualToString:[NSString stringWithUTF8String:@encode(float)]]
        ||[encode isEqualToString:[NSString stringWithUTF8String:@encode(double)]]
        ) {
        return @"REAL";
    }
    if ([encode rangeOfString:@"String"].length) {
        return @"TEXT";
    }
    if ([encode rangeOfString:@"NSNumber"].length) {
        return @"REAL";
    }
    if ([encode rangeOfString:@"NSData"].length) {
        return @"BLOB";
    }
    if ([encode rangeOfString:@"NSDate"].length) {
        return @"TIMESTAMP";
    }
    return nil;
}


@end
