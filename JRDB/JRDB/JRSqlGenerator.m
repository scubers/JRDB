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
#import <FMDB.h>

@implementation JRSqlGenerator

+ (NSString *)createTableSql4Clazz:(Class<JRPersistent>)clazz {
    NSMutableString *sql = [NSMutableString string];
    // create table 'tableName' (ID text primary key, 'p1' 'type1')
    NSString *tableName = [JRReflectUtil shortClazzName:clazz];
    [sql appendFormat:@"create table %@ (_ID text primary key ", tableName];
    
    NSArray *array = [JRReflectUtil ivarAndEncode4Clazz:clazz];
    NSArray *excludes = [clazz jr_excludePropertyNames];
    
    for (NSDictionary *dict in array) {
        NSString *name = dict.allKeys.firstObject;
        if ((excludes.count && [excludes containsObject:name]) || isID(name)) {
            continue;
        }
        NSString *type = [self typeWithEncodeName:dict.allValues.firstObject];
        [sql appendFormat:@", %@ %@", name, type];
    }
    [sql appendString:@");"];
    NSLog(@"sql: %@", sql);
    return sql;
}

+ (NSString *)updateTableSql4Clazz:(Class<JRPersistent>)clazz inDB:(FMDatabase *)db {
    NSString *tableName = [JRReflectUtil shortClazzName:clazz];
    if (![db tableExists:tableName]) {
        return [self createTableSql4Clazz:clazz];
    }
    
    NSArray *array = [JRReflectUtil ivarAndEncode4Clazz:clazz];
    NSArray *excludes = [clazz jr_excludePropertyNames];
    // alter 'tableName' add 'name' 'type', 'name2' 'type'
    BOOL flag = NO;
    NSMutableString *sql = [NSMutableString string];
    [sql appendFormat:@"alter %@ add ", tableName];
    for (NSDictionary *dict in array) {
        NSString *name = dict.allKeys.firstObject;
        if (![db columnExists:name inTableWithName:tableName] && ![excludes containsObject:name]
            ) {
            [sql appendFormat:@"%@ %@,", name , [self typeWithEncodeName:dict.allValues.firstObject]];
            flag = YES;
        }
        if ([array indexOfObject:dict] != array.count-1) {
            [sql appendString:@","];
        }
    }
    [sql appendString:@" where _ID = ? ;"];
    NSLog(@"sql: %@", sql);
    return flag ? sql : nil;
}

+ (NSString *)deleteTableSql4Clazz:(Class<JRPersistent>)clazz{
    NSString *sql = [NSString stringWithFormat:@"drop table %@", [JRReflectUtil shortClazzName:clazz]];
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
    
    NSArray *array = [JRReflectUtil ivarAndEncode4Clazz:[obj class]];
    NSArray *excludes = [[obj class] jr_excludePropertyNames];
    
    for (NSDictionary *dict in array) {
        NSString *name = dict.allKeys.firstObject;
        if ((excludes.count && [excludes containsObject:name]) || isID(name)) {
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
    
    NSArray *array = [JRReflectUtil ivarAndEncode4Clazz:[obj class]];
    NSArray *excludes = [[obj class] jr_excludePropertyNames];
    
    for (NSDictionary *dict in array) {
        NSString *name = dict.allKeys.firstObject;
        if ((excludes.count && [excludes containsObject:name] && [columns containsObject:name]) || isID(name)) {
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

+ (NSString *)sql4FindAll:(Class<JRPersistent>)clazz {
    NSString *sql = [NSString stringWithFormat:@"select * from %@ ;", [JRReflectUtil shortClazzName:clazz]];
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
    return @"";
}


@end
