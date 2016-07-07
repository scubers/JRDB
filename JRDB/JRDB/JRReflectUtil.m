//
//  JRReflectUtil.m
//  JRDB
//
//  Created by JMacMini on 16/5/10.
//  Copyright © 2016年 Jrwong. All rights reserved.
//

#import "JRReflectUtil.h"
#import "NSObject+Reflect.h"
#import "OBJCProperty.h"
#import "JRActivatedProperty.h"

@implementation JRReflectUtil

+ (NSDictionary<NSString *, NSString *> *)propNameAndEncode4Clazz:(Class<JRPersistent>)clazz {
    NSString *className = [NSString stringWithUTF8String:class_getName(clazz)];
    if ([className isEqualToString:@"NSObject"]) {
        return nil;
    } else {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        id aobj = [[NSClassFromString(NSStringFromClass(clazz)) alloc] init];
        if ([aobj conformsToProtocol:@protocol(JRPersistent)]) {
            [[clazz objc_properties] enumerateObjectsUsingBlock:^(OBJCProperty * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([[clazz jr_excludePropertyNames] containsObject:obj.ivarName]) {return ;}
                if (!obj.ivarName.length) { return; }
                dict[obj.ivarName] = obj.typeEncoding;
            }];
        }
        [dict addEntriesFromDictionary:[self propNameAndEncode4Clazz:class_getSuperclass(clazz)]];
        return dict;
    }
    
}

+ (const char *)typeEncoding4InstanceMethod:(SEL)selector inClazz:(Class)clazz {
    Method method = class_getInstanceMethod(clazz, selector);
    return method_getTypeEncoding(method);
}

+ (void)exchangeClazz:(Class)clazz method:(SEL)selector withMethod:(SEL)aSelector {
    [clazz objc_exchangeMethod:selector withMethod:aSelector];
}

+ (NSArray<JRActivatedProperty *> *)activitedProperties4Clazz:(Class<JRPersistent>)clazz {
    NSDictionary<NSString *, NSString *> *dict = [self propNameAndEncode4Clazz:clazz];
    NSMutableArray *properties = [NSMutableArray array];

    // 普通字段
    [dict enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull type, BOOL * _Nonnull stop) {
        if ([[clazz jr_excludePropertyNames] containsObject:key]){return;}
        NSString *dataBaseType = [self dataBaseTypeWithEncodeName:type];
        if (!dataBaseType) return;
        JRActivatedProperty *p = [JRActivatedProperty property:key relationShip:JRRelationNormal];
        p.dataBaseType = dataBaseType;
        p.dataBaseName = key;
        p.typeEncode = type;
        [properties addObject:p];
    }];

    // 一对一字段
    [[clazz jr_singleLinkedPropertyNames] enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, Class<JRPersistent>  _Nonnull obj, BOOL * _Nonnull stop) {
        JRActivatedProperty *p = [JRActivatedProperty property:key relationShip:JRRelationOneToOne];
        p.dataBaseType = [self dataBaseTypeWithEncodeName:[NSString stringWithUTF8String:@encode(NSString)]];
        p.clazz = obj;
        p.dataBaseName = SingleLinkColumn(key);
        p.typeEncode = NSStringFromClass(obj);
        [properties addObject:p];
    }];
    // 一对多字段
    [[clazz jr_oneToManyLinkedPropertyNames] enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, Class<JRPersistent>  _Nonnull subClazz, BOOL * _Nonnull stop) {
        JRActivatedProperty *p = [JRActivatedProperty property:key
                                                  relationShip:clazz == subClazz ? JRRelationChildren : JRRelationOneToMany];
        p.dataBaseType = [self dataBaseTypeWithEncodeName:[NSString stringWithUTF8String:@encode(NSString)]];
        p.clazz = subClazz;
        if (clazz == subClazz) {
            p.dataBaseName = ParentLinkColumn(key);
        }
        p.typeEncode = NSStringFromClass(subClazz);
        [properties addObject:p];
    }];

    return properties;
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
