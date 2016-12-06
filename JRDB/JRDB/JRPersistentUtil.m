//
//  JRPersistentUtil.m
//  JRDB
//
//  Created by 王俊仁 on 2016/12/7.
//  Copyright © 2016年 Jrwong. All rights reserved.
//

#import "JRPersistentUtil.h"
#import "OBJCProperty.h"
#import "JRActivatedProperty.h"

@implementation JRPersistentUtil


+ (NSArray<JRActivatedProperty *> *)allPropertesForClass:(Class<JRPersistent>)aClass {
    NSMutableArray<OBJCProperty *> *ops = [self objcpropertyWithClass:aClass];
    NSMutableArray<JRActivatedProperty *> *aps = [NSMutableArray array];

    [ops enumerateObjectsUsingBlock:^(OBJCProperty * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *dataBaseType = [self dataBaseTypeWithEncodeName:obj.typeEncoding];
        if (!dataBaseType) return ;

        JRActivatedProperty *p = [JRActivatedProperty property:obj.name relationShip:JRRelationNormal];
        p.dataBaseType = dataBaseType;
        p.dataBaseName = obj.ivarName;
        p.ivarName = obj.ivarName;
        p.typeEncode = obj.typeEncoding;
        [aps addObject:p];
    }];

    // 一对一字段
    [[aClass jr_singleLinkedPropertyNames] enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, Class<JRPersistent>  _Nonnull clazz, BOOL * _Nonnull stop) {

        __block OBJCProperty *op = nil;
        [ops enumerateObjectsUsingBlock:^(OBJCProperty * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj.name isEqualToString:key]) {
                op = obj;
                *stop = YES;
            }
        }];

        if (!op) {
            return ;
        }

        JRActivatedProperty *p = [JRActivatedProperty property:op.name relationShip:JRRelationOneToOne];
        p.dataBaseType = [self dataBaseTypeWithEncodeName:[NSString stringWithUTF8String:@encode(NSString)]];
        p.clazz = clazz;
        p.dataBaseName = SingleLinkColumn(key);
        p.typeEncode = NSStringFromClass(clazz);
        p.ivarName = op.ivarName;
        [aps addObject:p];
    }];

    // 一对多字段
    [[aClass jr_oneToManyLinkedPropertyNames] enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, Class<JRPersistent>  _Nonnull subClazz, BOOL * _Nonnull stop) {

        __block OBJCProperty *op = nil;
        [ops enumerateObjectsUsingBlock:^(OBJCProperty * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj.name isEqualToString:key]) {
                op = obj;
                *stop = YES;
            }
        }];

        if (!op) {
            return ;
        }

        JRActivatedProperty *p = [JRActivatedProperty property:op.name
                                                  relationShip:aClass == subClazz ? JRRelationChildren : JRRelationOneToMany];
        p.dataBaseType = [self dataBaseTypeWithEncodeName:[NSString stringWithUTF8String:@encode(NSString)]];
        p.clazz = subClazz;
        p.ivarName = op.ivarName;
        if (aClass == subClazz) {
            p.dataBaseName = ParentLinkColumn(key);
        }
        p.typeEncode = NSStringFromClass(subClazz);
        [aps addObject:p];
    }];
    
    return aps;
}

/**
 返回所有可以被入库的objcproperty 包括其父类

 @param aClazz aClazz description
 */
+ (NSMutableArray<OBJCProperty *> *)objcpropertyWithClass:(Class<JRPersistent>)aClass {
    NSMutableArray<OBJCProperty *> *array = [NSMutableArray array];

    [[aClass objc_properties] enumerateObjectsUsingBlock:^(OBJCProperty * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([[aClass jr_excludePropertyNames] containsObject:obj.ivarName]) {return ;}
        if (!obj.ivarName.length) { return; }
        [array addObject:obj];
    }];

    Class superClass = class_getSuperclass(aClass);
    if (!superClass) return array;
    [array addObjectsFromArray:[self objcpropertyWithClass:superClass]];
    return array;
}

+ (NSString *)dataBaseTypeWithEncodeName:(NSString *)encode {
    if ([encode isEqualToString:[NSString stringWithUTF8String:@encode(int)]]
        ||[encode isEqualToString:[NSString stringWithUTF8String:@encode(unsigned int)]]
        ||[encode isEqualToString:[NSString stringWithUTF8String:@encode(long)]]
        ||[encode isEqualToString:[NSString stringWithUTF8String:@encode(unsigned long)]]
        ||[encode isEqualToString:[NSString stringWithUTF8String:@encode(BOOL)]]
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

@end
