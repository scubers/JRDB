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
#import "JRFMDBResultSetHandler.h"
#import "JRFMDBResultSetHandler+Chain.h"

@implementation FMDatabase (Chain)

- (BOOL)jr_executeUpdateChain:(JRDBChain *)chain {
    if (chain.operation == CInsert) {
        if (!chain.isRecursive) {
            if ([chain.target isKindOfClass:[NSArray class]]) {
                return [self jr_saveObjectsOnly:chain.target useTransaction:chain.useTransaction];
            }
            return [self jr_saveOneOnly:chain.target useTransaction:chain.useTransaction];
        } else {
            if ([chain.target isKindOfClass:[NSArray class]]) {
                return [self jr_saveObjects:chain.target useTransaction:chain.useTransaction];
            }
            return [self jr_saveOne:chain.target useTransaction:chain.useTransaction];
        }
    }
    else if (chain.operation == CUpdate) {
        if (!chain.isRecursive) {
            if ([chain.target isKindOfClass:[NSArray class]]) {
                return [self jr_updateObjectsOnly:chain.target columns:[self _needUpdateColumnsInChain:chain] useTransaction:chain.useTransaction];
            }
            return [self jr_updateOneOnly:chain.target columns:[self _needUpdateColumnsInChain:chain] useTransaction:chain.useTransaction];
        } else {
            if ([chain.target isKindOfClass:[NSArray class]]) {
                return [self jr_updateObjects:chain.target columns:[self _needUpdateColumnsInChain:chain] useTransaction:chain.useTransaction];
            }
            return [self jr_updateOne:chain.target columns:[self _needUpdateColumnsInChain:chain] useTransaction:chain.useTransaction];
        }
    }
    else if (chain.operation == CDelete) {
        if (!chain.isRecursive) {
            if ([chain.target isKindOfClass:[NSArray class]]) {
                return [self jr_deleteObjectsOnly:chain.target useTransaction:chain.useTransaction];
            }
            return [self jr_deleteOneOnly:chain.target useTransaction:chain.useTransaction];
        } else {
            if ([chain.target isKindOfClass:[NSArray class]]) {
                return [self jr_deleteObjects:chain.target useTransaction:chain.useTransaction];
            }
            return [self jr_deleteOne:chain.target useTransaction:chain.useTransaction];
        }
    }
    else if (chain.operation == CDeleteAll) {
        if (!chain.isRecursive) {
            return [self jr_deleteAllOnly:chain.target useTransaction:chain.useTransaction];
        } else {
            return [self jr_deleteAll:chain.target useTransaction:chain.useTransaction];
        }
    }
    else {
        NSAssert(NO, @"%s :%@", __FUNCTION__, @"chain operation should be Inset or Update or Delete or DeleteAll");
        return NO;
    }
}

- (void)jr_executeUpdateChain:(JRDBChain *)chain complete:(JRDBComplete)complete {
    if (chain.operation == CInsert) {
        if (!chain.isRecursive) {
            if ([chain.target isKindOfClass:[NSArray class]]) {
                [self jr_saveObjectsOnly:chain.target useTransaction:chain.useTransaction complete:complete];
            } else {
                [self jr_saveOneOnly:chain.target useTransaction:chain.useTransaction complete:complete];
            }
        } else {
            if ([chain.target isKindOfClass:[NSArray class]]) {
                [self jr_saveObjects:chain.target useTransaction:chain.useTransaction complete:complete];
            } else {
                [self jr_saveOne:chain.target useTransaction:chain.useTransaction complete:complete];
            }
        }
    }
    else if (chain.operation == CUpdate) {
        if (!chain.isRecursive) {
            if ([chain.target isKindOfClass:[NSArray class]]) {
                [self jr_updateObjectsOnly:chain.target columns:[self _needUpdateColumnsInChain:chain] useTransaction:chain.useTransaction complete:complete];
            } else {
                [self jr_updateOneOnly:chain.target columns:[self _needUpdateColumnsInChain:chain] useTransaction:chain.useTransaction complete:complete];
            }

        } else {
            if ([chain.target isKindOfClass:[NSArray class]]) {
                [self jr_updateObjects:chain.target columns:[self _needUpdateColumnsInChain:chain] useTransaction:chain.useTransaction complete:complete];
            } else {
                [self jr_updateOne:chain.target columns:[self _needUpdateColumnsInChain:chain] useTransaction:chain.useTransaction  complete:complete];
            }
        }
    }
    else if (chain.operation == CDelete) {
        if (!chain.isRecursive) {
            if ([chain.target isKindOfClass:[NSArray class]]) {
                [self jr_deleteObjectsOnly:chain.target useTransaction:chain.useTransaction complete:complete];
            } else {
                [self jr_deleteOneOnly:chain.target useTransaction:chain.useTransaction complete:complete];
            }
        } else {
            if ([chain.target isKindOfClass:[NSArray class]]) {
                [self jr_deleteObjects:chain.target useTransaction:chain.useTransaction complete:complete];
            } else {
                [self jr_deleteOne:chain.target useTransaction:chain.useTransaction complete:complete];
            }
        }
    }
    else if (chain.operation == CDeleteAll) {
        if (!chain.isRecursive) {
            [self jr_deleteAllOnly:chain.target useTransaction:chain.useTransaction complete:complete];
        } else {
            [self jr_deleteAll:chain.target useTransaction:chain.useTransaction  complete:complete];
        }
    }
    else {
        NSAssert(NO, @"%s :%@", __FUNCTION__, @"chain operation should be Inset or Update or Delete or DeleteAll");
    }
}

- (id)jr_executeQueryChain:(JRDBChain *)chain {
    JRSql *sql = [JRSqlGenerator sql4ChainSelect:chain];
    FMResultSet *resultset = [self jr_executeQuery:sql];
    return [JRFMDBResultSetHandler handleResultSet:resultset forClazz:chain.target];
}

- (id)jr_executeCustomizedQueryChain:(JRDBChain *)chain {
    JRSql *sql = [JRSqlGenerator sql4ChainCustomizedSelect:chain];
    FMResultSet *resultSet = [self jr_executeQuery:sql];
    return [JRFMDBResultSetHandler handleResultSet:resultSet forChain:chain];
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
