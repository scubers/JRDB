//
//  JRSqlGenerator.m
//  JRDB
//
//  Created by JMacMini on 16/5/10.
//  Copyright © 2016年 Jrwong. All rights reserved.
//

#import "JRDBMgr.h"
#import "JRDBChain.h"
#import "NSObject+JRDB.h"
#import "JRSqlGenerator.h"
#import "NSObject+Reflect.h"
#import "JRActivatedProperty.h"
#import "JRPersistentUtil.h"

@implementation JRSql

@synthesize sqlString = _sqlString;
@synthesize args = _args;

+ (instancetype)sql:(NSString *)sql args:(NSArray *)args {
    JRSql *jrsql = [[self alloc] init];
    jrsql->_sqlString = sql;
    jrsql->_args = [args mutableCopy];
    return jrsql;
}

- (NSMutableArray *)args {
    if (!_args) {
        _args = [NSMutableArray array];
    }
    return _args;
}

- (NSString *)description {
    return _sqlString ? _sqlString : @"";
}

@end


@implementation JRSqlGenerator

+ (NSString *)getTableNameForClazz:(Class<JRPersistent>)clazz {
    return [clazz jr_tableName];
}

// create table 'tableName' (ID text primary key, 'p1' 'type1')
+ (JRSql *)createTableSql4Clazz:(Class<JRPersistent>)clazz table:(NSString * _Nullable)table{

    NSArray<JRActivatedProperty *> *ap = [clazz jr_activatedProperties];


    NSString *tableName  = table ?: [self getTableNameForClazz:clazz];
    NSMutableString *sql = [NSMutableString string];
    
    [sql appendFormat:@"create table if not exists %@ (%@ text primary key ", tableName, DBIDKey];

    [ap enumerateObjectsUsingBlock:^(JRActivatedProperty * _Nonnull prop, NSUInteger idx, BOOL * _Nonnull stop) {
        // 如果是关键字'ID' 或 '_ID' 则继续循环
        if (isID(prop.ivarName)) {return;}

        switch (prop.relateionShip) {
            case JRRelationNormal:
            case JRRelationOneToOne:
            case JRRelationChildren:
            {
                [sql appendFormat:@", %@ %@", prop.dataBaseName, prop.dataBaseType];
                break;
            }
            default:
                break;
        }
    }];

    [sql appendString:@");"];
    JRSql *jrsql = [JRSql sql:sql args:nil];
    return jrsql;
}

// {alter 'tableName' add column xx}
+ (NSArray<JRSql *> *)updateTableSql4Clazz:(Class<JRPersistent>)clazz inDB:(id<JRPersistentHandler>)db table:(NSString * _Nullable)table {
    NSString *tableName  = table ?: [self getTableNameForClazz:clazz];
    // 检测表是否存在, 不存在则直接返回创建表语句
    if (![db jr_tableExists:tableName]) { return @[[self createTableSql4Clazz:clazz table:tableName]]; }

    NSArray<JRActivatedProperty *> *ap = [clazz jr_activatedProperties];
    NSMutableArray *sqls = [NSMutableArray array];

    [ap enumerateObjectsUsingBlock:^(JRActivatedProperty * _Nonnull prop, NSUInteger idx, BOOL * _Nonnull stop) {
        // 如果是关键字'ID' 或 '_ID' 则继续循环
        if (isID(prop.ivarName)) {return;}
        if ([db jr_columnExists:prop.dataBaseName inTable:tableName]) { return; }

        JRSql *jrsql;
        switch (prop.relateionShip) {
            case JRRelationNormal:
            case JRRelationOneToOne:
            case JRRelationChildren:
            {
                jrsql = [JRSql sql:[NSString stringWithFormat:@"alter table %@ add column %@ %@;", tableName, prop.dataBaseName, prop.dataBaseType] args:nil];
                [sqls addObject:jrsql];
                break;
            }
            default: return;
        }
    }];

    return sqls;
}


+ (JRSql *)dropTableSql4Clazz:(Class<JRPersistent>)clazz table:(NSString * _Nullable)table{
    NSString *sql = [NSString stringWithFormat:@"drop table if exists %@ ;", table ?: [self getTableNameForClazz:clazz]];
    JRSql *jrsql = [JRSql sql:sql args:nil];
    return jrsql;
}

// insert into tablename (_ID) values (?)
+ (JRSql *)sql4Insert:(id<JRPersistent>)obj toDB:(id<JRPersistentHandler>)db table:(NSString * _Nullable)table {
    
    NSString *tableName = table ?: [self getTableNameForClazz:[obj class]];
//    NSArray<JRActivatedProperty *> *ap = [JRReflectUtil activitedProperties4Clazz:[obj class]];
    NSArray<JRActivatedProperty *> *ap = [[obj class] jr_activatedProperties];
    NSMutableArray *argsList = [NSMutableArray array];
    NSMutableString *sql     = [NSMutableString string];
    NSMutableString *sql2    = [NSMutableString string];
    
    [sql appendFormat:@" insert into %@ ('%@' ", tableName, DBIDKey];
    [sql2 appendFormat:@" values ( ? "];
    
    [ap enumerateObjectsUsingBlock:^(JRActivatedProperty * _Nonnull prop, NSUInteger idx, BOOL * _Nonnull stop) {
        // 如果是关键字'ID' 或 '_ID' 则继续循环
        if (isID(prop.ivarName)) {return;}
        if (![db jr_columnExists:prop.dataBaseName inTable:tableName]) { return; }
        
        // 拼接语句
        [sql appendFormat:@" , %@", prop.dataBaseName];
        [sql2 appendFormat:@" , ?"];
        
        id value;
        switch (prop.relateionShip) {
            case JRRelationNormal:
            {
                value = [(NSObject *)obj valueForKey:prop.propertyName];
                break;
            }
            case JRRelationOneToOne:
            {
                NSObject<JRPersistent> *sub = [((NSObject *)obj) valueForKey:prop.propertyName];
                value = [sub ID];
                break;
            }
            case JRRelationChildren:
            {
                NSString *parentID = [((NSObject *)obj) jr_parentLinkIDforKey:prop.propertyName];
                value = parentID;
                break;
            }
            default: return;
        }
        
        // 空值转换
        if (!value) { value = [NSNull null]; }
        // 添加参数
        [argsList addObject:value];
        
    }];
    
    
    
    [sql appendString:@")"];
    [sql2 appendString:@");"];
    [sql appendString:sql2];

    JRSql *jrsql = [JRSql sql:sql args:argsList];
    return jrsql;
}

+ (JRSql *)sql4Delete:(id<JRPersistent>)obj table:(NSString * _Nullable)table {
    NSString *sql = [NSString stringWithFormat:@"delete from %@ where %@ = ? ;", table ?: [self getTableNameForClazz:[obj class]], [JRPersistentUtil getPrimaryKeyByName:[[obj class] jr_primaryKey] inClass:[obj class]]];
    JRSql *jrsql = [JRSql sql:sql args:@[[obj jr_primaryKeyValue]]];
    return jrsql;

}

+ (JRSql *)sql4DeleteAll:(Class<JRPersistent>)clazz table:(NSString * _Nullable)table {
    NSString *sql = [NSString stringWithFormat:@"delete from %@", table ?: [self getTableNameForClazz:clazz]];
    JRSql *jrsql = [JRSql sql:sql args:nil];
    return jrsql;

}

// update 'tableName' set name = 'abc' where xx = xx
+ (JRSql *)sql4Update:(id<JRPersistent>)obj columns:(NSArray<NSString *> *)columns toDB:(id<JRPersistentHandler>)db table:(NSString * _Nullable)table {
    
    NSArray<JRActivatedProperty *> *ap = [[obj class] jr_activatedProperties];
    
    NSString *tableName      = table ?: [self getTableNameForClazz:[obj class]];
    NSMutableArray *argsList = [NSMutableArray array];
    NSMutableString *sql     = [NSMutableString string];
    
    [sql appendFormat:@" update %@ set ", tableName];
    
    [ap enumerateObjectsUsingBlock:^(JRActivatedProperty * _Nonnull prop, NSUInteger idx, BOOL * _Nonnull stop) {
        // 如果是关键字'ID' 或 '_ID' 则继续循环
        if (isID(prop.ivarName)) {return;}
        // 是否在指定更新列中
        if (columns.count && ![columns containsObject:prop.propertyName]) { return; }
        if (![db jr_columnExists:prop.dataBaseName inTable:tableName]) { return; }
        
        id value;
        switch (prop.relateionShip) {
            case JRRelationNormal:
            {
                value = [(NSObject *)obj valueForKey:prop.propertyName];
                break;
            }
            case JRRelationOneToOne:
            {
                NSObject<JRPersistent> *sub = [((NSObject *)obj) valueForKey:prop.propertyName];
                if (sub && ![sub ID]) {// 如果有新的子对象，则不更新
                    return;
                }
                [((NSObject *)obj) jr_setSingleLinkID:[sub ID] forKey:prop.propertyName];
                value = [sub ID];
                break;
            }
            case JRRelationChildren:
            {
                NSString *parentID = [((NSObject *)obj) jr_parentLinkIDforKey:prop.propertyName];
                value = parentID;
                break;
            }
            default: return;
        }
        [sql appendFormat:@" %@ = ?,", prop.dataBaseName];
        // 空值转换
        if (!value) { value = [NSNull null]; }
        // 添加参数
        [argsList addObject:value];

    }];
    
    
    if ([sql hasSuffix:@","]) {
        sql = [[sql substringToIndex:sql.length - 1] mutableCopy];
    }
    
    [sql appendFormat:@" where %@ = ? ;", [JRPersistentUtil getPrimaryKeyByName:[[obj class] jr_primaryKey] inClass:[obj class]]];
    [argsList addObject:[obj jr_primaryKeyValue]];

    JRSql *jrsql = [JRSql sql:sql args:argsList];
    return jrsql;

}

+ (JRSql * _Nonnull)sql4GetByIDWithClazz:(Class<JRPersistent> _Nonnull)clazz ID:(NSString *)ID table:(NSString * _Nullable)table {
    NSString *condition = [NSString stringWithFormat:@"%@=?", DBIDKey];
    return [self sql4GetColumns:nil
                    byCondition:condition
                         params:@[ID]
                          clazz:clazz
                        groupBy:nil
                        orderBy:nil
                          limit:nil
                         isDesc:NO
                          table:nil];
}

+ (JRSql *)sql4GetByPrimaryKeyWithClazz:(Class<JRPersistent>)clazz primaryKey:(id _Nonnull)primaryKey table:(NSString * _Nullable)table {

    NSString *condition = [NSString stringWithFormat:@"%@=?", [JRPersistentUtil getPrimaryKeyByName:[clazz jr_primaryKey] inClass:clazz]];
    return [self sql4GetColumns:nil
                    byCondition:condition
                         params:@[primaryKey]
                          clazz:clazz
                        groupBy:nil
                        orderBy:nil
                          limit:nil
                         isDesc:NO
                          table:nil];
}

+ (JRSql *)sql4FindAll:(Class<JRPersistent>)clazz orderby:(NSString *)orderby isDesc:(BOOL)isDesc table:(NSString * _Nullable)table {
    return [self sql4GetColumns:nil
                    byCondition:nil
                         params:nil
                          clazz:clazz
                        groupBy:nil
                        orderBy:nil
                          limit:nil
                         isDesc:NO
                          table:nil];
}

#pragma mark - convenience

+ (JRSql *)sql4CountByPrimaryKey:(id)pk clazz:(Class<JRPersistent>)clazz table:(NSString * _Nullable)table {
    
    
    NSString *sql = [NSString stringWithFormat:@"select count(1) from %@ where %@ = ?", table ?: [self getTableNameForClazz:clazz], [JRPersistentUtil getPrimaryKeyByName:[clazz jr_primaryKey] inClass:clazz]];
    JRSql *jrsql = [JRSql sql:sql args:@[pk]];
    return jrsql;
}

+ (JRSql *)sql4CountByID:(NSString *)ID clazz:(Class<JRPersistent>)clazz table:(NSString * _Nullable)table {
    NSString *sql = [NSString stringWithFormat:@"select count(1) from %@ where %@ = ?"
                     , table ?: [self getTableNameForClazz:clazz]
                     , DBIDKey];
    JRSql *jrsql = [JRSql sql:sql args:@[ID]];
    return jrsql;
}

+ (JRSql *)sql4GetColumns:(NSArray<NSString *> *)columns
              byCondition:(NSString *)condition
                   params:(NSArray *)params
                    clazz:(Class<JRPersistent>)clazz
                  groupBy:(NSString *)groupBy
                  orderBy:(NSString *)orderBy
                    limit:(NSString *)limit
                   isDesc:(BOOL)isDesc
                    table:(NSString *)table
{

    NSMutableArray *argList = [NSMutableArray array];
    NSString *tableName = table ?: [self getTableNameForClazz:clazz];
    NSMutableString *sqlString = [NSMutableString string];

    if (columns.count) {
        [sqlString appendString:@" select "];
        [columns enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            idx ? [sqlString appendFormat:@", %@ ", obj] : [sqlString appendFormat:@"%@", obj];
        }];
    } else {
        [sqlString appendString:@" select * "];
    }
    
    [sqlString appendFormat:@" from %@ where 1=1 ", tableName];

    if (condition) {
        [sqlString appendFormat:@" and (%@) ", condition];
    }

    if (params.count) {
        [argList addObjectsFromArray:params];
    }

    // group
    if (groupBy.length) {
        JRActivatedProperty *ap = [JRPersistentUtil activityWithPropertyName:groupBy inClass:clazz];
        [sqlString appendFormat:@" group by %@ ", ap.dataBaseName?:groupBy];
    }
    // orderby
    if (orderBy.length) {
        JRActivatedProperty *ap = [JRPersistentUtil activityWithPropertyName:orderBy inClass:clazz];
        [sqlString appendFormat:@" order by %@ ", ap.dataBaseName?:orderBy];
    }
    // desc asc
    if (isDesc && orderBy.length) {[sqlString appendString:@" desc "];}
    // limit
    if (limit.length) { [sqlString appendFormat:@" %@ ", limit]; }

    [sqlString appendString:@";"];

    JRSql *jrsql = [JRSql sql:sqlString args:argList];
    return jrsql;

}

+ (BOOL)isIgnoreProperty:(NSString *)property inClazz:(Class<JRPersistent>)clazz {
    NSArray *excludes = [clazz jr_excludePropertyNames];
    return [excludes containsObject:property] || isID(property);
}



@end


@implementation JRSqlGenerator (Chain)

+ (JRSql *)sql4Chain:(JRDBChain *)chain {
    
    NSMutableString *sqlString = [NSMutableString string];
    NSMutableArray *argList = [NSMutableArray array];
    
    [sqlString appendString:@" select "];
    
    if (chain.operation == CSelectCount) {
        [sqlString appendString:@" count(1) "];
    } else if (chain.selectColumns.count) {
        [chain.selectColumns enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            idx ? [sqlString appendFormat:@", %@ ", obj] : [sqlString appendFormat:@"%@", obj];
        }];
    } else {
        [sqlString appendString:@" * "];
    }
    
    [sqlString appendString:@" from "];
    
    if (chain.subChain) {
        JRSql *sql = [self sql4Chain:chain.subChain];
        [sqlString appendFormat:@" (%@) ", sql.sqlString];
        [argList addObjectsFromArray:sql.args];
    } else {
        [sqlString appendString:chain.tableName ?: [self getTableNameForClazz:chain.targetClazz]];
    }
    
    [sqlString appendString:@" where 1=1 "];
    
    NSAssert(!(chain.whereString.length && chain.whereId.length), @"where condition should not hold more than one!!!");
    NSAssert(!(chain.whereString.length && chain.wherePK), @"where condition should not hold more than one!!!");
    NSAssert(!(chain.whereId.length && chain.wherePK), @"where condition should not hold more than one!!!");
    
    
    if (chain.whereString.length) { // where 语句
        [sqlString appendFormat:@" and (%@)", chain.whereString];
        [argList addObjectsFromArray:chain.parameters];
        
    } else if (chain.whereId.length) {// where id = ? 语句
        [sqlString appendFormat:@" and ( %@ = ?)", DBIDKey];
        [argList addObject:chain.whereId];
        
    } else if (chain.wherePK) { // where pk = ? 语句
        [sqlString appendFormat:@" and ( %@ = ?)", [JRPersistentUtil getPrimaryKeyByName:[chain.targetClazz jr_primaryKey] inClass:chain.targetClazz]];
        [argList addObject:chain.wherePK];
        
    } else if (chain.conditions.count) {
        [chain.conditions enumerateObjectsUsingBlock:^(JRDBChainCondition * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString *sql = [NSString stringWithFormat:@" %@ (%@ %@ ?) "
                             , obj.typeString
                             , [JRPersistentUtil activityWithPropertyName:obj.propName inClass:chain.targetClazz].dataBaseName
                             , [obj operatorString]
                             ];
            [sqlString appendFormat:@"%@", sql];
            [argList addObject:obj.param];
        }];
    }
    
    // group
    if (chain.groupBy.length) {
        JRActivatedProperty *ap = [JRPersistentUtil activityWithPropertyName:chain.groupBy inClass:chain.targetClazz];
        [sqlString appendFormat:@" group by %@ ", ap.dataBaseName?:chain.groupBy];
    }
    // orderby
    if (chain.orderBy.length) {
        JRActivatedProperty *ap = [JRPersistentUtil activityWithPropertyName:chain.orderBy inClass:chain.targetClazz];
        [sqlString appendFormat:@" order by %@ ", ap.dataBaseName?:chain.orderBy];
    }
    // desc asc
    if (chain.isDesc && chain.orderBy.length) {[sqlString appendString:@" desc "];}
    // limit
    if (chain.limitString.length) { [sqlString appendFormat:@" %@ ", chain.limitString]; }
    
    // 有可能是子查询，不能加 『;』
//    [sqlString appendString:@";"];
    
    JRSql *jrsql = [JRSql sql:sqlString args:argList];
    return jrsql;
}

@end


