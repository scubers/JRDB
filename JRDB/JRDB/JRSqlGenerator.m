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
    [sql appendFormat:@"create table %@ (ID text primary key", tableName];
    
    NSArray *array = [JRReflectUtil ivarAndEncode4Clazz:clazz];
    NSArray *excludes = [clazz jr_excludePropertyNames];
    
    for (NSDictionary *dict in array) {
        NSString *name = dict.allKeys.firstObject;
        if (excludes.count && [excludes containsObject:name]) {
            continue;
        }
        NSString *type = [self typeWithEncodeName:dict.allValues.firstObject];
        [sql appendFormat:@", %@ %@", name, type];
    }
    [sql appendString:@");"];
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
    [sql appendString:@" where ID = ? ;"];
    return flag ? sql : nil;
}

+ (NSString *)deleteTableSql4Clazz:(Class<JRPersistent>)clazz {
    return [NSString stringWithFormat:@"drop table %@", [JRReflectUtil shortClazzName:clazz]];
}


+ (NSString *)sql4Insert:(Class<JRPersistent>)clazz {
    NSMutableString *sql = [NSMutableString string];
    NSString *tableName = [JRReflectUtil shortClazzName:clazz];
    [sql appendFormat:@" insert into %@ values (ID = ?, ", tableName];
    
    NSArray *array = [JRReflectUtil ivarAndEncode4Clazz:clazz];
    NSArray *excludes = [clazz jr_excludePropertyNames];
    
    for (NSDictionary *dict in array) {
        NSString *name = dict.allKeys.firstObject;
        if (excludes.count && [excludes containsObject:name]) {
            continue;
        }
        [sql appendFormat:@" %@ = ? ", name];
        if ([array indexOfObject:dict] != array.count - 1) {
            [sql appendString:@","];
        }
    }
    [sql appendString:@");"];
    return sql;
}

+ (NSString *)sql4Delete:(Class<JRPersistent>)clazz {
    return [NSString stringWithFormat:@"delete from %@ where ID = ? ;", [JRReflectUtil shortClazzName:clazz]];
}

+ (NSString *)sql4Update:(Class<JRPersistent>)clazz columns:(NSArray<NSString *> *)columns {
    NSMutableString *sql = [NSMutableString string];
    NSString *tableName = [JRReflectUtil shortClazzName:clazz];
    [sql appendFormat:@" update %@ set ", tableName];
    
    NSArray *array = [JRReflectUtil ivarAndEncode4Clazz:clazz];
    NSArray *excludes = [clazz jr_excludePropertyNames];
    
    for (NSDictionary *dict in array) {
        NSString *name = dict.allKeys.firstObject;
        if (excludes.count && [excludes containsObject:name] && [columns containsObject:name]) {
            continue;
        }
        [sql appendFormat:@" %@ = ? ", name];
        if ([array indexOfObject:dict] != array.count - 1) {
            [sql appendString:@","];
        }
    }
    [sql appendString:@" where ID = ? ;"];
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
