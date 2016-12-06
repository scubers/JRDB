//
//  JRFMDBResultSetHandler.m
//  JRDB
//
//  Created by JMacMini on 16/5/11.
//  Copyright © 2016年 Jrwong. All rights reserved.
//

#import "JRFMDBResultSetHandler.h"
#import "JRReflectUtil.h"
#import <objc/runtime.h>
#import "NSObject+JRDB.h"
#import "JRActivatedProperty.h"
#import "JRDBChain.h"
#import <FMDB/FMDB.h>

@implementation JRFMDBResultSetHandler

+ (NSArray<id<JRPersistent>> *)handleResultSet:(FMResultSet *)resultSet forClazz:(Class<JRPersistent>)clazz columns:(NSArray * _Nullable)columns {
    NSMutableArray *list = [NSMutableArray array];
    
    NSArray<JRActivatedProperty *> *props = [clazz jr_activatedProperties];
    
    while ([resultSet next]) {
        Class c = objc_getClass(class_getName(clazz));
        NSObject<JRPersistent> *obj = [[c alloc] init];
        
        NSString *ID = [resultSet stringForColumn:@"_ID"];
        [obj setID:ID];
        
        [props enumerateObjectsUsingBlock:^(JRActivatedProperty * _Nonnull prop, NSUInteger idx, BOOL * _Nonnull stop) {
            if (isID(prop.ivarName)) { return; }
            if (columns && ![columns containsObject:prop.ivarName]) { return; }
            
            RetDataType type = [self typeWithEncode:prop.typeEncode];
            switch (type) {
                case RetDataTypeNSData: {
                    id value = [resultSet dataForColumn:prop.dataBaseName];
                    [obj setValue:value forKey:prop.propertyName];
                    break;
                }
                case RetDataTypeString: {
                    id value = [resultSet stringForColumn:prop.dataBaseName];
                    [obj setValue:value forKey:prop.propertyName];
                    break;
                }
                case RetDataTypeNSNumber: {
                    id value = [NSNumber numberWithDouble:[resultSet doubleForColumn:prop.dataBaseName]];
                    [obj setValue:value forKey:prop.propertyName];
                    break;
                }
                case RetDataTypeInt: {
                    int temp = [resultSet intForColumn:prop.dataBaseName];
                    [obj setValue:@(temp) forKey:prop.propertyName];
                    break;
                }
                case RetDataTypeUnsignedInt: {
                    unsigned long long temp = [resultSet unsignedLongLongIntForColumn:prop.dataBaseName];
                    [obj setValue:@(temp) forKey:prop.propertyName];
                    break;
                }
                case RetDataTypeLong: {
                    long temp = [resultSet longForColumn:prop.dataBaseName];
                    [obj setValue:@(temp) forKey:prop.propertyName];
                    break;
                }
                case RetDataTypeLongLong: {
                    long long temp = [resultSet longLongIntForColumn:prop.dataBaseName];
                    [obj setValue:@(temp) forKey:prop.propertyName];
                    break;
                }
                case RetDataTypeUnsignedLong: {
                    unsigned long long temp = [resultSet unsignedLongLongIntForColumn:prop.dataBaseName];
                    [obj setValue:@(temp) forKey:prop.propertyName];
                    break;
                }
                case RetDataTypeUnsignedLongLong:{
                    unsigned long long temp = [resultSet unsignedLongLongIntForColumn:prop.dataBaseName];
                    [obj setValue:@(temp) forKey:prop.propertyName];
                    break;
                }
                case RetDataTypeDouble: {
                    double temp = [resultSet doubleForColumn:prop.dataBaseName];
                    [obj setValue:@(temp) forKey:prop.propertyName];
                    break;
                }
                case RetDataTypeFloat: {
                    float temp = [resultSet doubleForColumn:prop.dataBaseName];
                    [obj setValue:@(temp) forKey:prop.propertyName];
                    break;
                }
                case RetDataTypeNSDate:{
                    NSDate *date = [resultSet dateForColumn:prop.dataBaseName];
                    [obj setValue:date forKey:prop.propertyName];
                    break;
                }
                case RetDataTypeUnsupport:
                default:
                    break;
            }
        }];

        // 检查一对一关联的字段
        [[clazz jr_singleLinkedPropertyNames] enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, Class<JRPersistent>  _Nonnull clazz, BOOL * _Nonnull stop) {
            int idx = [resultSet columnIndexForName:SingleLinkColumn(key)];
            if (idx >= 0) {
                NSString *ID = [resultSet stringForColumnIndex:idx];
                [obj jr_setSingleLinkID:ID forKey:key];
            }
        }];
        
        // 一对多 父子关系  AModel -> NSArray<AModel *> *_aModels; 存储父对象字段
        [[clazz jr_oneToManyLinkedPropertyNames] enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, Class<JRPersistent>  _Nonnull subClazz, BOOL * _Nonnull stop) {
            if (clazz == subClazz) {
                NSString *parentID = [resultSet stringForColumn:ParentLinkColumn(key)];
                [obj jr_setParentLinkID:parentID forKey:key];
            }
        }];
        
        
        [list addObject:obj];
    }
    [resultSet close];
    return list;
}

+ (RetDataType)typeWithEncode:(NSString *)encode {
    
    if (strcmp(encode.UTF8String, @encode(int)) == 0
        ||strcmp(encode.UTF8String, @encode(BOOL)) == 0) {
        return RetDataTypeInt;
    }
    if (strcmp(encode.UTF8String, @encode(unsigned int)) == 0) {
        return RetDataTypeUnsignedInt;
    }
    if (strcmp(encode.UTF8String, @encode(long)) == 0) {
        return RetDataTypeLong;
    }
    if (strcmp(encode.UTF8String, @encode(unsigned long)) == 0){
        return RetDataTypeUnsignedLong;
    }
    if (strcmp(encode.UTF8String, @encode(float)) == 0) {
        return RetDataTypeFloat;
    }
    if (strcmp(encode.UTF8String, @encode(double)) == 0) {
        return RetDataTypeDouble;
    }
    if ([encode rangeOfString:@"String"].length) {
        return RetDataTypeString;
    }
    if ([encode rangeOfString:@"NSNumber"].length) {
        return RetDataTypeNSNumber;
    }
    if ([encode rangeOfString:@"NSData"].length) {
        return RetDataTypeNSData;
    }
    if ([encode rangeOfString:@"NSDate"].length) {
        return RetDataTypeNSDate;
    }
    
    return RetDataTypeUnsupport;
}


@end



@implementation JRFMDBResultSetHandler (Chain)

+ (id)handleResultSet:(FMResultSet *)resultSet forChain:(JRDBChain *)chain {

    if (chain.operation == CSelectCount) {
        [resultSet next];
        NSNumber *count = @([resultSet unsignedLongLongIntForColumnIndex:0]);
        [resultSet close];
        return count;
    }

    NSMutableArray *list = [NSMutableArray array];
    NSArray<JRActivatedProperty *> *props = [chain.targetClazz jr_activatedProperties];
    NSMutableArray *selectCols = [chain.selectColumns mutableCopy];

    while ([resultSet next]) {
        Class c = objc_getClass(class_getName(chain.targetClazz));
        NSObject<JRPersistent> *obj = [[c alloc] init];

        NSString *ID = [resultSet stringForColumn:@"_ID"];
        [obj setID:ID];


        NSString *primaryKey = [((Class<JRPersistent>)chain.target) jr_customPrimarykey];
        if (primaryKey && ![selectCols containsObject:primaryKey]) {
            [selectCols addObject:primaryKey];
        }

        [props enumerateObjectsUsingBlock:^(JRActivatedProperty * _Nonnull prop, NSUInteger idx, BOOL * _Nonnull stop) {
            if (isID(prop.ivarName)) { return; }
            if (![selectCols containsObject:prop.ivarName]) { return; }

            RetDataType type = [self typeWithEncode:prop.typeEncode];
            switch (type) {
                case RetDataTypeNSData: {
                    id value = [resultSet dataForColumn:prop.dataBaseName];
                    [obj setValue:value forKey:prop.propertyName];
                    break;
                }
                case RetDataTypeString: {
                    id value = [resultSet stringForColumn:prop.dataBaseName];
                    [obj setValue:value forKey:prop.propertyName];
                    break;
                }
                case RetDataTypeNSNumber: {
                    id value = [NSNumber numberWithDouble:[resultSet doubleForColumn:prop.dataBaseName]];
                    [obj setValue:value forKey:prop.propertyName];
                    break;
                }
                case RetDataTypeInt: {
                    int temp = [resultSet intForColumn:prop.dataBaseName];
                    [obj setValue:@(temp) forKey:prop.propertyName];
                    break;
                }
                case RetDataTypeUnsignedInt: {
                    unsigned long long temp = [resultSet unsignedLongLongIntForColumn:prop.dataBaseName];
                    [obj setValue:@(temp) forKey:prop.propertyName];
                    break;
                }
                case RetDataTypeLong: {
                    long temp = [resultSet longForColumn:prop.dataBaseName];
                    [obj setValue:@(temp) forKey:prop.propertyName];
                    break;
                }
                case RetDataTypeLongLong: {
                    long long temp = [resultSet longLongIntForColumn:prop.dataBaseName];
                    [obj setValue:@(temp) forKey:prop.propertyName];
                    break;
                }
                case RetDataTypeUnsignedLong: {
                    unsigned long long temp = [resultSet unsignedLongLongIntForColumn:prop.dataBaseName];
                    [obj setValue:@(temp) forKey:prop.propertyName];
                    break;
                }
                case RetDataTypeUnsignedLongLong:{
                    unsigned long long temp = [resultSet unsignedLongLongIntForColumn:prop.dataBaseName];
                    [obj setValue:@(temp) forKey:prop.propertyName];
                    break;
                }
                case RetDataTypeDouble: {
                    double temp = [resultSet doubleForColumn:prop.dataBaseName];
                    [obj setValue:@(temp) forKey:prop.propertyName];
                    break;
                }
                case RetDataTypeFloat: {
                    float temp = [resultSet doubleForColumn:prop.dataBaseName];
                    [obj setValue:@(temp) forKey:prop.propertyName];
                    break;
                }
                case RetDataTypeNSDate:{
                    NSDate *date = [resultSet dateForColumn:prop.dataBaseName];
                    [obj setValue:date forKey:prop.propertyName];
                    break;
                }
                case RetDataTypeUnsupport:
                default:
                    break;
            }
        }];


        [list addObject:obj];
    }
    [resultSet close];
    return list;
}

@end
