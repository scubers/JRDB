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

@import FMDB;

typedef enum {
    RetDataTypeInt = 1,
    RetDataTypeUnsignedInt,
    RetDataTypeLong,
    RetDataTypeLongLong,
    RetDataTypeUnsignedLong,
    RetDataTypeUnsignedLongLong,
    RetDataTypeDouble,
    RetDataTypeFloat,
    RetDataTypeString,
    
    RetDataTypeNSNumber,
    RetDataTypeNSData,
    RetDataTypeNSDate,
    
    RetDataTypeUnsupport
} RetDataType;

@implementation JRFMDBResultSetHandler

+ (NSArray<id<JRPersistent>> *)handleResultSet:(FMResultSet *)resultSet forClazz:(Class<JRPersistent>)clazz {
    NSMutableArray *list = [NSMutableArray array];
    
    NSArray<JRActivatedProperty *> *props = [clazz jr_activatedProperties];
//    NSDictionary *dict = [JRReflectUtil propNameAndEncode4Clazz:clazz];
    
    while ([resultSet next]) {
        Class c = objc_getClass(class_getName(clazz));
        NSObject<JRPersistent> *obj = [[c alloc] init];
        
        NSString *ID = [resultSet stringForColumn:@"_ID"];
        [obj setID:ID];
        
        [props enumerateObjectsUsingBlock:^(JRActivatedProperty * _Nonnull prop, NSUInteger idx, BOOL * _Nonnull stop) {
            if (isID(prop.name)) { return; }
            RetDataType type = [self typeWithEncode:prop.typeEncode];
            switch (type) {
                case RetDataTypeNSData: {
                    id value = [resultSet dataForColumn:prop.dataBaseName];
                    [obj setValue:value forKey:prop.name];
                    break;
                }
                case RetDataTypeString: {
                    id value = [resultSet stringForColumn:prop.dataBaseName];
                    [obj setValue:value forKey:prop.name];
                    break;
                }
                case RetDataTypeNSNumber: {
                    id value = [NSNumber numberWithDouble:[resultSet doubleForColumn:prop.dataBaseName]];
                    [obj setValue:value forKey:prop.name];
                    break;
                }
                case RetDataTypeInt: {
                    Ivar ivar = class_getInstanceVariable(clazz, [prop.name UTF8String]);
                    *(int *)((__bridge void *)(obj) + ivar_getOffset(ivar)) = [resultSet intForColumn:prop.dataBaseName];
                    break;
                }
                case RetDataTypeUnsignedInt: {
                    Ivar ivar = class_getInstanceVariable(clazz, [prop.name UTF8String]);
                    *(unsigned int *)((__bridge void *)(obj) + ivar_getOffset(ivar)) = (unsigned int)[resultSet unsignedLongLongIntForColumn:prop.dataBaseName];
                    break;
                }
                case RetDataTypeLong: {
                    Ivar ivar = class_getInstanceVariable(clazz, [prop.name UTF8String]);
                    *(long *)((__bridge void *)(obj) + ivar_getOffset(ivar)) = [resultSet longForColumn:prop.dataBaseName];
                    break;
                }
                case RetDataTypeLongLong: {
                    Ivar ivar = class_getInstanceVariable(clazz, [prop.name UTF8String]);
                    *(long long *)((__bridge void *)(obj) + ivar_getOffset(ivar)) = [resultSet longLongIntForColumn:prop.dataBaseName];
                    break;
                }
                case RetDataTypeUnsignedLong: {
                    Ivar ivar = class_getInstanceVariable(clazz, [prop.name UTF8String]);
                    *(unsigned long *)((__bridge void *)(obj) + ivar_getOffset(ivar)) = (unsigned long)[resultSet unsignedLongLongIntForColumn:prop.dataBaseName];
                    break;
                }
                case RetDataTypeUnsignedLongLong:{
                    Ivar ivar = class_getInstanceVariable(clazz, [prop.name UTF8String]);
                    *(unsigned long long *)((__bridge void *)(obj) + ivar_getOffset(ivar)) = [resultSet unsignedLongLongIntForColumn:prop.dataBaseName];
                    break;
                }
                case RetDataTypeDouble: {
                    Ivar ivar = class_getInstanceVariable(clazz, [prop.name UTF8String]);
                    *(double *)((__bridge void *)(obj) + ivar_getOffset(ivar)) = [resultSet doubleForColumn:prop.dataBaseName];
                    break;
                }
                case RetDataTypeFloat: {
                    Ivar ivar = class_getInstanceVariable(clazz, [prop.name UTF8String]);
                    *(float *)((__bridge void *)(obj) + ivar_getOffset(ivar)) = [resultSet doubleForColumn:prop.dataBaseName];
                    break;
                }
                case RetDataTypeNSDate:{
                    NSDate *date = [resultSet dateForColumn:prop.dataBaseName];
                    [obj setValue:date forKey:prop.name];
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
    
    return list;
}

+ (RetDataType)typeWithEncode:(NSString *)encode {
    if ([encode isEqualToString:[NSString stringWithUTF8String:@encode(int)]]
        ||[encode isEqualToString:[NSString stringWithUTF8String:@encode(BOOL)]]) {
        return RetDataTypeInt;
    }
    if ([encode isEqualToString:[NSString stringWithUTF8String:@encode(unsigned int)]]) {
        return RetDataTypeUnsignedInt;
    }
    if ([encode isEqualToString:[NSString stringWithUTF8String:@encode(long)]]) {
        return RetDataTypeLong;
    }
    if ([encode isEqualToString:[NSString stringWithUTF8String:@encode(unsigned long)]]){
        return RetDataTypeUnsignedLong;
    }
    if ([encode isEqualToString:[NSString stringWithUTF8String:@encode(float)]]) {
        return RetDataTypeFloat;
    }
    if ([encode isEqualToString:[NSString stringWithUTF8String:@encode(double)]]) {
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
