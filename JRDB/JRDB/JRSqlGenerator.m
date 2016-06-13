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
#import "JRQueryCondition.h"
#import "NSObject+Reflect.h"
#import "JRDBMgr.h"
#import "JRSql.h"
#import "JRActivatedProperty.h"

void SqlLog(id sql) {
    if ([JRDBMgr shareInstance].debugMode) {
        NSLog(@"%@", sql);
    }
}

@import FMDB;

@implementation JRSqlGenerator

// create table 'tableName' (ID text primary key, 'p1' 'type1')
+ (JRSql *)createTableSql4Clazz:(Class<JRPersistent>)clazz {

    NSArray<JRActivatedProperty *> *ap = [clazz jr_activatedProperties];

    NSString *tableName  = [clazz shortClazzName];
    NSMutableString *sql = [NSMutableString string];
    
    [sql appendFormat:@"create table if not exists %@ (_ID text primary key ", tableName];

    [ap enumerateObjectsUsingBlock:^(JRActivatedProperty * _Nonnull prop, NSUInteger idx, BOOL * _Nonnull stop) {
        // 如果是关键字'ID' 或 '_ID' 则继续循环
        if (isID(prop.name)) {return;}

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
    SqlLog(jrsql);
    return jrsql;
}

// {alter 'tableName' add column xx}
+ (NSArray<JRSql *> *)updateTableSql4Clazz:(Class<JRPersistent>)clazz inDB:(FMDatabase *)db {
    NSString *tableName = [clazz shortClazzName];
    // 检测表是否存在, 不存在则直接返回创建表语句
    if (![db tableExists:tableName]) { return @[[self createTableSql4Clazz:clazz]]; }

    NSArray<JRActivatedProperty *> *ap = [clazz jr_activatedProperties];

    NSDictionary *dict   = [JRReflectUtil propNameAndEncode4Clazz:clazz];
    NSArray *excludes    = [clazz jr_excludePropertyNames];
    NSMutableArray *sqls = [NSMutableArray array];

    [ap enumerateObjectsUsingBlock:^(JRActivatedProperty * _Nonnull prop, NSUInteger idx, BOOL * _Nonnull stop) {
        // 如果是关键字'ID' 或 '_ID' 则继续循环
        if (isID(prop.name)) {return;}

        if ([db columnExists:prop.dataBaseName inTableWithName:tableName]) { return; }

        JRSql *jrsql;
        switch (prop.relateionShip) {
            case JRRelationNormal:
            {
                jrsql = [JRSql sql:[NSString stringWithFormat:@"alter table %@ add column %@ %@;", tableName, prop.dataBaseName, prop.dataBaseType] args:nil];
                [sqls addObject:jrsql];
                break;
            }
            case JRRelationOneToOne:
            {
                break;
            }
            case JRRelationChildren:
            {
                break;
            }
            default:
                break;
        }

    }];

    // alter 'tableName' add 'name' 'type';
    for (NSString *name in dict.allKeys) {

        // 如果是关键字'ID' 或 '_ID' 或是 jr_excludePropertyNames 则继续循环
        NSString *type = [self typeWithEncodeName:dict[name]];
        if (!type) { continue; }
        
        if (![db columnExists:name inTableWithName:tableName] && ![excludes containsObject:name]) {

            JRSql *jrsql = [JRSql sql:[NSString stringWithFormat:@"alter table %@ add column %@ %@;", tableName, name, type] args:nil];
            [sqls addObject:jrsql];
        }
    }
    
    // 检测一对一关系
    [[clazz jr_singleLinkedPropertyNames] enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, Class<JRPersistent>  _Nonnull obj, BOOL * _Nonnull stop) {
        
        if ([self isIgnoreProperty:key inClazz:clazz]) { return ;}
        
        if (![db columnExists:SingleLinkColumn(key) inTableWithName:tableName]) {
            JRSql *jrsql = [JRSql sql:[NSString stringWithFormat:@"alter table %@ add column %@ TEXT;", tableName, SingleLinkColumn(key)] args:nil];
            [sqls addObject:jrsql];
        }
    }];
    
    // 一对多 父子关系  AModel -> NSArray<AModel *> *_aModels;
    [[clazz jr_oneToManyLinkedPropertyNames] enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, Class<JRPersistent>  _Nonnull obj, BOOL * _Nonnull stop) {
        
        if ([self isIgnoreProperty:key inClazz:clazz]) { return ;}
        
        if (clazz == obj && ![db columnExists:ParentLinkColumn(key) inTableWithName:tableName]) {
            JRSql *jrsql = [JRSql sql:[NSString stringWithFormat:@"alter table %@ add column %@ TEXT;", tableName, ParentLinkColumn(key)] args:nil];
            [sqls addObject:jrsql];
        }
    }];
    
    
    SqlLog(sqls);
    return sqls;
}


+ (JRSql *)dropTableSql4Clazz:(Class<JRPersistent>)clazz {
    NSString *sql = [NSString stringWithFormat:@"drop table if exists %@ ;",[clazz shortClazzName]];
    JRSql *jrsql = [JRSql sql:sql args:nil];
    SqlLog(jrsql);
    return jrsql;
}

// insert into tablename (_ID) values (?)
+ (JRSql *)sql4Insert:(id<JRPersistent>)obj toDB:(FMDatabase * _Nonnull)db {
    
    NSString *tableName = [[obj class] shortClazzName];
    
    NSMutableArray *argsList = [NSMutableArray array];
    NSDictionary *dict       = [JRReflectUtil propNameAndEncode4Clazz:[obj class]];
    NSMutableString *sql     = [NSMutableString string];
    NSMutableString *sql2    = [NSMutableString string];
    
    [sql appendFormat:@" insert into %@ ('_ID' ", tableName];
    [sql2 appendFormat:@" values ( ? "];
    
    for (NSString *name in dict.allKeys) {
        // 如果是关键字'ID' 或 '_ID' 或是 jr_excludePropertyNames 则继续循环
        if ([self isIgnoreProperty:name inClazz:[obj class]]) { continue; }
        
        // 检测字段是否存在
        if (![db columnExists:name inTableWithName:tableName]) { continue; }
        
        // 检测是否支持字段
        if (![self typeWithEncodeName:dict[name]]) { continue;}
        
        // 拼接语句
        [sql appendFormat:@" , %@", name];
        [sql2 appendFormat:@" , ?"];

        // 空值转换
        id value = [(NSObject *)obj valueForKey:name];
        if (!value) { value = [NSNull null]; }
        
        // 添加参数
        [argsList addObject:value];
    }
    
    // 检测一对一字段
    [[[obj class] jr_singleLinkedPropertyNames] enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, Class<JRPersistent>  _Nonnull clazz, BOOL * _Nonnull stop) {
        NSObject<JRPersistent> *value = [((NSObject *)obj) valueForKey:key];
        [sql appendFormat:@" , %@", SingleLinkColumn(key)];
        [sql2 appendFormat:@" , ?"];
        [argsList addObject:[value ID] ? [value ID] : [NSNull null]];
    }];
    
    // 一对多 父子关系  AModel -> NSArray<AModel *> *_aModels; 存储父对象字段
    [[[obj class] jr_oneToManyLinkedPropertyNames] enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, Class<JRPersistent>  _Nonnull clazz, BOOL * _Nonnull stop) {
        if ([obj class] == clazz) {
            [sql appendFormat:@" , %@", ParentLinkColumn(key)];
            [sql2 appendFormat:@" , ?"];
            
            NSString *parentID = [((NSObject *)obj) jr_parentLinkIDforKey:key];
            [argsList addObject:parentID ? parentID : [NSNull null]];
        }
    }];
    
    
    [sql appendString:@")"];
    [sql2 appendString:@");"];
    [sql appendString:sql2];

    JRSql *jrsql = [JRSql sql:sql args:argsList];
    SqlLog(jrsql);
    return jrsql;
}

+ (JRSql *)sql4Delete:(id<JRPersistent>)obj {
    NSString *sql = [NSString stringWithFormat:@"delete from %@ where %@ = ? ;", [[obj class] shortClazzName], [[obj class] jr_primaryKey]];
    JRSql *jrsql = [JRSql sql:sql args:nil];
    SqlLog(jrsql);
    return jrsql;

}

+ (JRSql *)sql4DeleteAll:(Class<JRPersistent>)clazz {
    NSString *sql = [NSString stringWithFormat:@"delete from %@", [clazz shortClazzName]];
    JRSql *jrsql = [JRSql sql:sql args:nil];
    SqlLog(jrsql);
    return jrsql;

}

// update 'tableName' set name = 'abc' where xx = xx
+ (JRSql *)sql4Update:(id<JRPersistent>)obj columns:(NSArray<NSString *> *)columns toDB:(FMDatabase * _Nonnull)db {
    
    NSString *tableName      = [[obj class] shortClazzName];
    NSMutableArray *argsList = [NSMutableArray array];
    NSMutableString *sql     = [NSMutableString string];
    NSDictionary *dict       = [JRReflectUtil propNameAndEncode4Clazz:[obj class]];
    
    [sql appendFormat:@" update %@ set ", tableName];
    
    for (NSString *name in dict.allKeys) {
        
        if ([self isIgnoreProperty:name inClazz:[obj class]]) { continue; }
        
        // 是否在指定更新列中
        if (columns.count && ![columns containsObject:name]) { continue; }
        
        // 检测字段是否存在
        if (![db columnExists:name inTableWithName:tableName]) { continue; }
        
        // 检测是否支持字段
        if (![self typeWithEncodeName:dict[name]]) { continue; }
        
        [sql appendFormat:@" %@ = ?,", name];
        
        // 空值转换
        id value = [(NSObject *)obj valueForKey:name];
        if (!value) { value = [NSNull null]; }
        
        [argsList addObject:value];
    }
    
    // 检测一对一字段
    [[[obj class] jr_singleLinkedPropertyNames] enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, Class<JRPersistent>  _Nonnull clazz, BOOL * _Nonnull stop) {
        
        id<JRPersistent> value = [((NSObject *)obj) valueForKey:key];
        [((NSObject *)obj) jr_setSingleLinkID:[value ID] forKey:key];
        
        [sql appendFormat:@" %@ = ?,", SingleLinkColumn(key)];
        [argsList addObject: [value ID] ? [value ID] : [NSNull null]];
    }];
    
    // 一对多 父子关系  AModel -> NSArray<AModel *> *_aModels; 存储父对象字段
    [[[obj class] jr_oneToManyLinkedPropertyNames] enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, Class<JRPersistent>  _Nonnull clazz, BOOL * _Nonnull stop) {
        if ([obj class] == clazz) {
            
            // 是否在指定更新列中
            if (columns.count && ![columns containsObject:key]) { return; }
            // 检测字段是否存在
            if (![db columnExists:key inTableWithName:tableName]) { return; }
            
            [sql appendFormat:@" %@ = ?,", ParentLinkColumn(key)];
            NSString *parentID = [((NSObject *)obj) jr_parentLinkIDforKey:key];
            [argsList addObject:parentID ? parentID : [NSNull null]];
        }
    }];
    
    
    if ([sql hasSuffix:@","]) {
        sql = [[sql substringToIndex:sql.length - 1] mutableCopy];
    }
    
    [sql appendFormat:@" where %@ = ? ;", [[obj class] jr_primaryKey]];

    JRSql *jrsql = [JRSql sql:sql args:argsList];
    SqlLog(jrsql);
    return jrsql;

}

+ (JRSql * _Nonnull)sql4GetByIDWithClazz:(Class<JRPersistent> _Nonnull)clazz {
    NSString *sql = [NSString stringWithFormat:@"select * from %@ where _ID = ?;", [clazz shortClazzName]];
    JRSql *jrsql = [JRSql sql:sql args:nil];
    SqlLog(jrsql);
    return jrsql;
}

+ (JRSql *)sql4GetByPrimaryKeyWithClazz:(Class<JRPersistent>)clazz {
    NSString *sql = [NSString stringWithFormat:@"select * from %@ where %@ = ?;", [clazz shortClazzName], [clazz jr_primaryKey]];
    JRSql *jrsql = [JRSql sql:sql args:nil];
    SqlLog(jrsql);
    return jrsql;

}

+ (JRSql *)sql4FindAll:(Class<JRPersistent>)clazz orderby:(NSString *)orderby isDesc:(BOOL)isDesc {
    NSString *sql = [NSString stringWithFormat:@"select * from %@ ", [clazz shortClazzName]];
    if (orderby.length) {
        sql = [sql stringByAppendingFormat:@" order by %@ ", orderby.length ? orderby : [clazz jr_primaryKey]];
    }
    sql = [sql stringByAppendingFormat:@" %@ ;", isDesc ? @"desc" : @""];

    JRSql *jrsql = [JRSql sql:sql args:nil];
    SqlLog(jrsql);
    return jrsql;

}

+ (JRSql *)sql4FindByConditions:(NSArray<JRQueryCondition *> *)conditions clazz:(Class<JRPersistent>)clazz groupBy:(NSString *)groupBy orderBy:(NSString *)orderBy limit:(NSString *)limit isDesc:(BOOL)isDesc {
    
    NSMutableArray *argList = [NSMutableArray array];
    NSMutableString *sql    = [NSMutableString string];
    
    [sql appendFormat:@" select * from %@ where 1=1 ", [clazz shortClazzName]];
    
    for (JRQueryCondition *condition in conditions) {
        
        [sql appendFormat:@" %@ (%@)", condition.type == JRQueryConditionTypeAnd ? @"and" : @"or", condition.condition];
        
        if (condition.args.count) {
            [argList addObjectsFromArray:condition.args];
        }
    }
    
    // group
    if (groupBy.length) { [sql appendFormat:@" group by %@ ", groupBy]; }
    // orderby
    if (orderBy.length) { [sql appendFormat:@" order by %@ ", orderBy]; }
    // desc asc
    if (isDesc) {[sql appendString:@" desc "];}
    // limit
    if (limit.length) { [sql appendFormat:@" %@ ", limit]; }
    
    [sql appendString:@";"];

    JRSql *jrsql = [JRSql sql:sql args:argList];
    SqlLog(jrsql);
    return jrsql;

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

#pragma mark - private method
+ (BOOL)isIgnoreProperty:(NSString *)property inClazz:(Class<JRPersistent>)clazz {
    NSArray *excludes = [clazz jr_excludePropertyNames];
    return [excludes containsObject:property] || isID(property);
}

@end
