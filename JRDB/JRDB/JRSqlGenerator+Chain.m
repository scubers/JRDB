//
//  JRSqlGenerator+Chain.m
//  JRDB
//
//  Created by JMacMini on 16/7/11.
//  Copyright © 2016年 Jrwong. All rights reserved.
//

#import "JRSqlGenerator+Chain.h"
#import "JRDBChain.h"
#import "JRPersistent.h"
#import "JRActivatedProperty.h"
#import "JRQueryCondition.h"
#import "JRReflectUtil.h"
#import "NSObject+Reflect.h"
#import "JRUtils.h"
#import "JRSql.h"

@implementation JRSqlGenerator (Chain)

+ (JRSql *)sql4Chain:(JRDBChain *)chain {
    switch (chain.operation) {
        case CInsert:return [self sql4ChainInsert:chain];
        case CUpdate:return [self sql4ChainUpdate:chain];
        case CDelete:return [self sql4ChainDelete:chain];
        case CDeleteAll:return [self sql4ChainDeleteAll:chain];
        case CSelect:return [self sql4ChainSelect:chain];
        default:return nil;
    }
}

+ (JRSql *)sql4ChainInsert:(JRDBChain *)chain {
    return [self sql4Insert:chain.target toDB:chain.db table:chain.tableName];
}

+ (JRSql *)sql4ChainDelete:(JRDBChain *)chain {
    return [self sql4Delete:chain.target table:chain.tableName];
}

+ (JRSql *)sql4ChainDeleteAll:(JRDBChain *)chain {
    return [self sql4DeleteAll:chain.target table:chain.tableName];
}

+ (JRSql *)sql4ChainUpdate:(JRDBChain *)chain {
    NSAssert(!(chain.columnsArray.count && chain.ignoreArray.count), @"Columns And Ignore could not use at the same chain!!");
    NSMutableArray *colums = nil;
    if (chain.columnsArray.count) {
        colums = [chain.columnsArray mutableCopy];
    } else if(chain.ignoreArray.count) {
        Class<JRPersistent> clazz = [chain.target class];
        [[clazz jr_activatedProperties] enumerateObjectsUsingBlock:^(JRActivatedProperty * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (![chain.ignoreArray containsObject:obj]) {
                [colums addObject:obj.name];
            }
        }];
    }
    return [self sql4Update:chain.target columns:colums toDB:chain.db table:chain.tableName];
}

+ (JRSql *)sql4ChainSelect:(JRDBChain *)chain {
    if (chain.isRecursive) {
        return [self sql4GetColumns:@[@"_ID"] byConditions:chain.queryCondition clazz:chain.target groupBy:chain.groupBy orderBy:chain.orderBy limit:chain.limitIn isDesc:chain.isDesc table:chain.tableName];
    } else {
        return [self sql4FindByConditions:chain.queryCondition clazz:chain.target groupBy:chain.groupBy orderBy:chain.orderBy limit:chain.limitIn isDesc:chain.isDesc table:chain.tableName];
    }
}

+ (JRSql *)sql4ChainCustomizedSelect:(JRDBChain *)chain {
    NSAssert(chain.tableName.length, @"customized query should specified a table");
    NSAssert(chain.target, @"customized query should specified a Class");
    
    NSString *tableName = chain.tableName;
//    NSString *asName = [NSString stringWithFormat:@"%@_%@", chain.tableName, [JRUtils uuid]];
    
    NSMutableString *sqlString = [NSMutableString string];
    [sqlString appendString:@" select "];
    
    if (chain.operation == CSelectCustomized) {
        // 默认把主键和ID放入select 列中
        NSMutableArray *selectCol = [chain.selectColumns mutableCopy];
        if (![selectCol containsObject:@"_ID"]) {
            [selectCol addObject:@"_ID"];
        }
        
        NSString *primaryKey = [((Class<JRPersistent>)chain.target) jr_customPrimarykey];
        if (primaryKey && ![selectCol containsObject:primaryKey]) {
            [selectCol addObject:primaryKey];
        }
        [selectCol enumerateObjectsUsingBlock:^(NSString * _Nonnull col, NSUInteger idx, BOOL * _Nonnull stop) {
            idx ? [sqlString appendFormat:@",%@", col] : [sqlString appendString:col];
        }];
        
    } else {
        [sqlString appendString:@" count(1) "];
    }
    
    [sqlString appendFormat:@" from %@ ", tableName];
    
    if (chain.whereString.length) {
        [sqlString appendFormat:@" %@ ",chain.whereString];
    }
    
    // group
    if (chain.groupBy.length) { [sqlString appendFormat:@" group by %@ ", chain.groupBy]; }
    // orderby
    if (chain.orderBy.length) { [sqlString appendFormat:@" order by %@ ", chain.orderBy]; }
    // desc asc
    if (chain.isDesc) {[sqlString appendString:@" desc "];}
    // limit
    if (chain.limitIn.length) { [sqlString appendFormat:@" %@ ", chain.limitIn]; }
    
    [sqlString appendString:@";"];
    
    JRSql *sql = [JRSql sql:sqlString args:chain.parameters];
    SqlLog(sql);
    return sql;
}

@end






