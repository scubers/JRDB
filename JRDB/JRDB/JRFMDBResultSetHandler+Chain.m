//
//  JRFMDBResultSetHandler+Chain.m
//  JRDB
//
//  Created by JMacMini on 16/7/12.
//  Copyright © 2016年 Jrwong. All rights reserved.
//

#import "JRFMDBResultSetHandler+Chain.h"
#import "JRDBChain.h"
#import "JRPersistent.h"
#import <objc/runtime.h>
#import "JRActivatedProperty.h"
#import "JRReflectUtil.h"
@import FMDB;

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
            if (isID(prop.name)) { return; }
            if (![selectCols containsObject:prop.name]) { return; }
            
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
                    Ivar ivar = class_getInstanceVariable(chain.targetClazz, [prop.name UTF8String]);
                    *(int *)((__bridge void *)(obj) + ivar_getOffset(ivar)) = [resultSet intForColumn:prop.dataBaseName];
                    break;
                }
                case RetDataTypeUnsignedInt: {
                    Ivar ivar = class_getInstanceVariable(chain.targetClazz, [prop.name UTF8String]);
                    *(unsigned int *)((__bridge void *)(obj) + ivar_getOffset(ivar)) = (unsigned int)[resultSet unsignedLongLongIntForColumn:prop.dataBaseName];
                    break;
                }
                case RetDataTypeLong: {
                    Ivar ivar = class_getInstanceVariable(chain.targetClazz, [prop.name UTF8String]);
                    *(long *)((__bridge void *)(obj) + ivar_getOffset(ivar)) = [resultSet longForColumn:prop.dataBaseName];
                    break;
                }
                case RetDataTypeLongLong: {
                    Ivar ivar = class_getInstanceVariable(chain.targetClazz, [prop.name UTF8String]);
                    *(long long *)((__bridge void *)(obj) + ivar_getOffset(ivar)) = [resultSet longLongIntForColumn:prop.dataBaseName];
                    break;
                }
                case RetDataTypeUnsignedLong: {
                    Ivar ivar = class_getInstanceVariable(chain.targetClazz, [prop.name UTF8String]);
                    *(unsigned long *)((__bridge void *)(obj) + ivar_getOffset(ivar)) = (unsigned long)[resultSet unsignedLongLongIntForColumn:prop.dataBaseName];
                    break;
                }
                case RetDataTypeUnsignedLongLong:{
                    Ivar ivar = class_getInstanceVariable(chain.targetClazz, [prop.name UTF8String]);
                    *(unsigned long long *)((__bridge void *)(obj) + ivar_getOffset(ivar)) = [resultSet unsignedLongLongIntForColumn:prop.dataBaseName];
                    break;
                }
                case RetDataTypeDouble: {
                    Ivar ivar = class_getInstanceVariable(chain.targetClazz, [prop.name UTF8String]);
                    *(double *)((__bridge void *)(obj) + ivar_getOffset(ivar)) = [resultSet doubleForColumn:prop.dataBaseName];
                    break;
                }
                case RetDataTypeFloat: {
                    Ivar ivar = class_getInstanceVariable(chain.targetClazz, [prop.name UTF8String]);
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
        
        
        [list addObject:obj];
    }
    [resultSet close];
    return list;
}

@end
