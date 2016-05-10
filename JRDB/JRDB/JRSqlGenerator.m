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

#define isID(name) ([name isEqualToString:@"ID"] || [name isEqualToString:@"_ID"])

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

+ (NSString *)deleteTableSql4Clazz:(Class<JRPersistent>)clazz{
    return [NSString stringWithFormat:@"drop table %@", [JRReflectUtil shortClazzName:clazz]];
}


+ (NSString *)sql4Insert:(id<JRPersistent>)obj args:(NSArray *__autoreleasing *)args{
    NSMutableArray *argsList = [NSMutableArray array];
    
    NSMutableString *sql = [NSMutableString string];
    NSString *tableName = [JRReflectUtil shortClazzName:[obj class]];
    [sql appendFormat:@" insert into %@ values (ID = ?, ", tableName];
    
    NSArray *array = [JRReflectUtil ivarAndEncode4Clazz:[obj class]];
    NSArray *excludes = [[obj class] jr_excludePropertyNames];
    
    for (NSDictionary *dict in array) {
        NSString *name = dict.allKeys.firstObject;
        if ((excludes.count && [excludes containsObject:name]) || isID(name)) {
            continue;
        }
        [sql appendFormat:@" %@ = ? ", name];
        NSLog(@"----%@", name);
        id value = [(NSObject *)obj valueForKey:name];
        if (!value) {
            value = [NSNull null];
        }
        [argsList addObject:value];
        
        if ([array indexOfObject:dict] != array.count - 1) {
            [sql appendString:@","];
        }
    }
    [sql appendString:@");"];
    *args = argsList;
    return sql;
}

+ (NSString *)sql4Delete:(id<JRPersistent>)obj {
    return [NSString stringWithFormat:@"delete from %@ where ID = ? ;", [JRReflectUtil shortClazzName:[obj class]]];
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
        
        if ([array indexOfObject:dict] != array.count - 1) {
            [sql appendString:@","];
        }
    }
    [sql appendString:@" where ID = ? ;"];
    *args = argsList;
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
