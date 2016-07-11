//
//  FMDatabase+Chain.m
//  JRDB
//
//  Created by JMacMini on 16/7/11.
//  Copyright © 2016年 Jrwong. All rights reserved.
//

#import "FMDatabase+Chain.h"
#import "JRSqlGenerator+Chain.h"
#import "JRSqlGenerator.h"
#import "JRSql.h"
#import "JRDBChain.h"
#import "FMDatabase+JRDB.h"
#import "JRActivatedProperty.h"

@implementation FMDatabase (Chain)

- (BOOL)jr_executeUpdateChain:(JRDBChain *)chain {
    if (chain.operation == CInsert) {
        if (chain.isRecursive) {
            return [self jr_saveOneOnly:chain.target useTransaction:chain.useTransaction];
        } else {
            return [self jr_saveOne:chain.target useTransaction:chain.useTransaction];
        }
    }
    if (chain.operation == CUpdate) {
        if (chain.isRecursive) {
            return [self jr_updateOneOnly:chain.target columns:[self _needUpdateColumnsInChain:chain] useTransaction:chain.useTransaction];
        } else {
            return [self jr_updateOne:chain.target columns:[self _needUpdateColumnsInChain:chain] useTransaction:chain.useTransaction];
        }
    }
    if (chain.operation == CDelete) {
        if (chain.isRecursive) {
            return [self jr_deleteOneOnly:chain.target useTransaction:chain.useTransaction];
        } else {
            return [self jr_deleteOne:chain.target useTransaction:chain.useTransaction];
        }
    }
    if (chain.operation == CDeleteAll) {
        if (chain.isRecursive) {
            return [self jr_deleteAllOnly:chain.target useTransaction:chain.useTransaction];
        } else {
            return [self jr_deleteAll:chain.target useTransaction:chain.useTransaction];
        }
    }
    
    NSAssert(NO, @"%s :%@", __FUNCTION__, @"chain operation should be Inset or Update or Delete or DeleteAll");
    return NO;
}

- (void)jr_executeUpdateChain:(JRDBChain *)chain complete:(JRDBComplete)complete {
    if (chain.operation == CInsert) {
        if (chain.isRecursive) {
            [self jr_saveOneOnly:chain.target useTransaction:chain.useTransaction complete:complete];
        } else {
            [self jr_saveOne:chain.target useTransaction:chain.useTransaction complete:complete];
        }
    }
    if (chain.operation == CUpdate) {
        if (chain.isRecursive) {
            [self jr_updateOneOnly:chain.target columns:[self _needUpdateColumnsInChain:chain] useTransaction:chain.useTransaction complete:complete];
        } else {
            [self jr_updateOne:chain.target columns:[self _needUpdateColumnsInChain:chain] useTransaction:chain.useTransaction  complete:complete];
        }
    }
    if (chain.operation == CDelete) {
        if (chain.isRecursive) {
            [self jr_deleteOneOnly:chain.target useTransaction:chain.useTransaction complete:complete];
        } else {
            [self jr_deleteOne:chain.target useTransaction:chain.useTransaction complete:complete];
        }
    }
    if (chain.operation == CDeleteAll) {
        if (chain.isRecursive) {
            [self jr_deleteAllOnly:chain.target useTransaction:chain.useTransaction complete:complete];
        } else {
            [self jr_deleteAll:chain.target useTransaction:chain.useTransaction  complete:complete];
        }
    }
    NSAssert(NO, @"%s :%@", __FUNCTION__, @"chain operation should be Inset or Update or Delete or DeleteAll");
}

- (NSArray<id<JRPersistent>> *)jr_executeQueryChain:(JRDBChain *)chain {
    return nil;
}

- (NSArray *)_needUpdateColumnsInChain:(JRDBChain *)chain {
    NSMutableArray *columns = nil;
    if (chain.columnsArray.count) {
        return chain.columnsArray;
    }
    else if (chain.ignoreArray.count) {
        Class<JRPersistent> clazz = [chain.target class];
        [[clazz jr_activatedProperties] enumerateObjectsUsingBlock:^(JRActivatedProperty * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (![chain.ignoreArray containsObject:obj]) {
                [columns addObject:obj.name];
            }
        }];
    }
    return columns;
}

@end
