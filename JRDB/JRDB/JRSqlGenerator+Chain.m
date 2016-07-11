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
    NSArray *conditions = nil;
    if (chain.whereString.length) {
        conditions = @[[JRQueryCondition condition:chain.whereString args:chain.parameters type:JRQueryConditionTypeAnd]];
    }
    return [self sql4FindByConditions:conditions clazz:chain.target groupBy:chain.groupBy orderBy:chain.orderBy limit:chain.limitIn isDesc:chain.isDesc table:chain.tableName];
}


@end






