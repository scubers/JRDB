//
//  FMDatabase+Chain.m
//  JRDB
//
//  Created by JMacMini on 16/7/11.
//  Copyright © 2016年 Jrwong. All rights reserved.
//

#import "FMDatabase+Chain.h"
#import "JRSqlGenerator.h"
#import "JRDBChain.h"
#import "FMDatabase+JRDB.h"
#import "JRActivatedProperty.h"
#import "JRFMDBResultSetHandler.h"


@implementation FMDatabase (Chain)

- (BOOL)jr_executeUpdateChain:(JRDBChain *)chain {
    
    if (chain.operation == CInsert) {
        if (!chain.isRecursive) {
            if (chain.targetArray) {
                return [self jr_saveObjectsOnly:chain.targetArray useTransaction:chain.useTransaction synchronized:chain.isSync complete:nil];
            }
            return [self jr_saveOneOnly:chain.target useTransaction:chain.useTransaction synchronized:chain.isSync complete:nil];
        } else {
            if (chain.targetArray) {
                return [self jr_saveObjects:chain.targetArray useTransaction:chain.useTransaction synchronized:chain.isSync complete:nil];
            }
            return [self jr_saveOne:chain.target useTransaction:chain.useTransaction synchronized:chain.isSync complete:nil];
        }
    }
    else if (chain.operation == CUpdate) {
        if (!chain.isRecursive) {
            if (chain.targetArray) {
                return [self jr_updateObjectsOnly:chain.targetArray columns:[self _needUpdateColumnsInChain:chain] useTransaction:chain.useTransaction synchronized:chain.isSync complete:nil];
            }
            return [self jr_updateOneOnly:chain.target columns:[self _needUpdateColumnsInChain:chain] useTransaction:chain.useTransaction synchronized:chain.isSync complete:nil];
        } else {
            if (chain.targetArray) {
                return [self jr_updateObjects:chain.targetArray columns:[self _needUpdateColumnsInChain:chain] useTransaction:chain.useTransaction synchronized:chain.isSync complete:nil];
            }
            return [self jr_updateOne:chain.target columns:[self _needUpdateColumnsInChain:chain] useTransaction:chain.useTransaction synchronized:chain.isSync complete:nil];
        }
    }
    else if (chain.operation == CDelete) {
        if (!chain.isRecursive) {
            if (chain.targetArray) {
                return [self jr_deleteObjectsOnly:chain.targetArray useTransaction:chain.useTransaction synchronized:chain.isSync complete:nil];
            }
            return [self jr_deleteOneOnly:chain.target useTransaction:chain.useTransaction synchronized:chain.isSync complete:nil];
        } else {
            if (chain.targetArray) {
                return [self jr_deleteObjects:chain.targetArray useTransaction:chain.useTransaction synchronized:chain.isSync complete:nil];
            }
            return [self jr_deleteOne:chain.target useTransaction:chain.useTransaction synchronized:chain.isSync complete:nil];
        }
    }
    else if (chain.operation == CSaveOrUpdate) {
        if (!chain.isRecursive) {
            if (chain.targetArray) {
                return [self jr_saveOrUpdateObjectsOnly:chain.targetArray useTransaction:chain.useTransaction synchronized:chain.isSync complete:nil];
            }
            return [self jr_saveOrUpdateOneOnly:chain.target useTransaction:chain.useTransaction synchronized:chain.isSync complete:nil];
        } else {
            if (chain.targetArray) {
                return [self jr_saveOrUpdateObjects:chain.targetArray useTransaction:chain.useTransaction synchronized:chain.isSync complete:nil];
            }
            return [self jr_saveOrUpdateOne:chain.target useTransaction:chain.useTransaction synchronized:chain.isSync complete:nil];
        }
    }
    else if (chain.operation == CDeleteAll) {
        if (!chain.isRecursive) {
            return [self jr_deleteAllOnly:chain.targetClazz useTransaction:chain.useTransaction synchronized:chain.isSync complete:nil];
        } else {
            return [self jr_deleteAll:chain.targetClazz useTransaction:chain.useTransaction synchronized:chain.isSync complete:nil];
        }
    }
    else if (chain.operation == CCreateTable) {
        return [self jr_createTable4Clazz:chain.targetClazz synchronized:chain.isSync complete:nil];
    }
    else if (chain.operation == CUpdateTable) {
        return [self jr_updateTable4Clazz:chain.targetClazz synchronized:chain.isSync complete:nil];
    }
    else if (chain.operation == CDropTable) {
        return [self jr_dropTable4Clazz:chain.targetClazz synchronized:chain.isSync complete:nil];
    }
    else if (chain.operation == CTruncateTable) {
        return [self jr_truncateTable4Clazz:chain.targetClazz synchronized:chain.isSync complete:nil];
    }
    else {
        NSAssert(NO, @"%s :%@", __FUNCTION__, @"chain operation should be Inset or Update or Delete or DeleteAll");
        return NO;
    }
}

- (id)jr_executeQueryChain:(JRDBChain *)chain {
    NSAssert(!chain.selectColumns.count, @"selectColumns should not has count in normal query");
    id result;
    if (!chain.isRecursive) {
        result = [self jr_getByJRSql:chain.querySql sync:chain.isSync resultClazz:chain.targetClazz columns:chain.selectColumns];
    } else {
        result = [self jr_findByJRSql:chain.querySql sync:chain.isSync resultClazz:chain.targetClazz columns:chain.selectColumns];
    }
    return [self _handleQueryResult:result forChain:chain];
}

- (id)jr_executeCustomizedQueryChain:(JRDBChain *)chain {
    return
    [self jr_executeSync:chain.isSync block:^id _Nullable(FMDatabase * _Nonnull db) {
        FMResultSet *resultSet = [self jr_executeQuery:chain.querySql];
        id result = [JRFMDBResultSetHandler handleResultSet:resultSet forChain:chain];
        return result;
    }];
}

#pragma mark - private method

- (NSArray *)_needUpdateColumnsInChain:(JRDBChain *)chain {
    NSAssert(!(chain.columnsArray.count && chain.ignoreArray.count), @"colums and ignore should not use at the same chain !!");
    NSMutableArray *columns = [NSMutableArray array];
    if (chain.columnsArray.count) {
        return chain.columnsArray;
    }
    else if (chain.ignoreArray.count) {
        Class<JRPersistent> clazz = chain.targetClazz;
        [[clazz jr_activatedProperties] enumerateObjectsUsingBlock:^(JRActivatedProperty * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (![chain.ignoreArray containsObject:obj.name]) {
                [columns addObject:obj.name];
            }
        }];
    }
    return columns.count ? columns : nil;
}

- (id)_handleQueryResult:(NSArray *)result forChain:(JRDBChain *)chain {
    return chain.operation == CSelectSingle ? [result firstObject] : result;
}

@end
