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

static NSRegularExpression *_reg;
+ (Class)getClassFromEncode:(NSString *)encode {
    if (!_reg) {
        NSError *error;
        _reg = [[NSRegularExpression alloc] initWithPattern:@"\\b\\w+\\b" options:NSRegularExpressionCaseInsensitive error:&error];
    }
    NSArray<NSTextCheckingResult *> *arr = [_reg matchesInString:encode options:NSMatchingReportProgress range:NSMakeRange(0, encode.length)];
    if (arr.count) {
        return NSClassFromString([encode substringWithRange:arr.firstObject.range]);
    }
    return nil;
}

+ (NSString *)uuid {
    CFUUIDRef uuidObject = CFUUIDCreate(kCFAllocatorDefault);
    NSString *uuidStr = (NSString *)CFBridgingRelease(CFUUIDCreateString(kCFAllocatorDefault, uuidObject));
    CFRelease(uuidObject);
    return uuidStr;
}

+ (NSArray<JRActivatedProperty *> *)allPropertesForClass:(Class<JRPersistent>)aClass {
    
    NSMutableArray<OBJCProperty *> *ops = [self objcpropertyWithClass:aClass];
    
    NSMutableArray<JRActivatedProperty *> *aps = [NSMutableArray array];
    
    NSArray *exclude = [aClass jr_excludePropertyNames];
    
    [ops enumerateObjectsUsingBlock:^(OBJCProperty * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        if ([exclude containsObject:obj.name]) return;
        
        NSString *dataBaseType = [self dataBaseTypeWithEncoding:obj.typeEncoding.UTF8String];
        
        if (!dataBaseType) return ;

        JRActivatedProperty *p = [JRActivatedProperty property:obj.name relationShip:JRRelationNormal];
        p.dataBaseType = dataBaseType;
        p.dataBaseName = [JRPersistentUtil columnNameWithPropertyName:obj.name inClass:aClass];
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
        p.dataBaseType = [self dataBaseTypeWithEncoding:@encode(NSString)];
        p.clazz = clazz;
        p.dataBaseName = SingleLinkColumn([JRPersistentUtil columnNameWithPropertyName:op.name inClass:aClass]);
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
        p.dataBaseType = [self dataBaseTypeWithEncoding:@encode(NSString)];
        p.clazz = subClazz;
        p.ivarName = op.ivarName;
        if (aClass == subClazz) {
            p.dataBaseName = ParentLinkColumn([JRPersistentUtil columnNameWithPropertyName:op.name inClass:aClass]);
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
        if ([[aClass jr_excludePropertyNames] containsObject:obj.name]) {return ;}
        if (!obj.ivarName.length) { return; } // 是否只有属性，没有变量
        [array addObject:obj];
    }];

    Class superClass = class_getSuperclass(aClass);
    if (!superClass) return array;
    [array addObjectsFromArray:[self objcpropertyWithClass:superClass]];
    return array;
}

+ (NSString *)dataBaseTypeWithEncoding:(const char *)encoding {
    
    NSString *encode = [NSString stringWithUTF8String:encoding];
    
    
    if (strcmp(encoding, @encode(int)) == 0
        || strcmp(encoding, @encode(unsigned int)) == 0
        || strcmp(encoding, @encode(long)) == 0
        || strcmp(encoding, @encode(unsigned long)) == 0
        || strcmp(encoding, @encode(BOOL)) == 0
        ) {
        return @"INTEGER";
    }
    if (strcmp(encoding, @encode(float)) == 0
        || strcmp(encoding, @encode(double)) == 0
        ) {
        return @"REAL";
    }
    
    Class clazz = [self getClassFromEncode:encode];
    
    if (clazz && [clazz isSubclassOfClass:[NSString class]]) {
        return @"TEXT";
    }
    if (clazz && [clazz isSubclassOfClass:[NSNumber class]]) {
        return @"REAL";
    }
    if (clazz && [clazz isSubclassOfClass:[NSData class]]) {
        return @"BLOB";
    }
    if (clazz && [clazz isSubclassOfClass:[NSDate class]]) {
        return @"TIMESTAMP";
    }
    return nil;
}

/**
 根据encode获取数据结果类型
 
 @param encoding encoding description
 */
+ (RetDataType)retDataTypeWithEncoding:(const char *)encoding {
    
    NSString *encode = [NSString stringWithUTF8String:encoding];
    
    if (strcmp(encoding, @encode(int)) == 0
        ||strcmp(encoding, @encode(BOOL)) == 0) {
        return RetDataTypeInt;
    }
    if (strcmp(encoding, @encode(unsigned int)) == 0) {
        return RetDataTypeUnsignedInt;
    }
    if (strcmp(encoding, @encode(long)) == 0) {
        return RetDataTypeLong;
    }
    if (strcmp(encoding, @encode(unsigned long)) == 0){
        return RetDataTypeUnsignedLong;
    }
    if (strcmp(encoding, @encode(float)) == 0) {
        return RetDataTypeFloat;
    }
    if (strcmp(encoding, @encode(double)) == 0) {
        return RetDataTypeDouble;
    }
    
    Class clazz = [self getClassFromEncode:encode];
    
    if (clazz && [clazz isSubclassOfClass:[NSString class]]) {
        return RetDataTypeString;
    }
    if (clazz && [clazz isSubclassOfClass:[NSNumber class]]) {
        return RetDataTypeNSNumber;
    }
    if (clazz && [clazz isSubclassOfClass:[NSData class]]) {
        return RetDataTypeNSData;
    }
    if (clazz && [clazz isSubclassOfClass:[NSDate class]]) {
        return RetDataTypeNSDate;
    }
    
    return RetDataTypeUnsupport;

}

+ (NSString *)columnNameWithPropertyName:(NSString *)propertyName inClass:(Class<JRPersistent>)aClass {
    NSDictionary *map = [aClass jr_databaseNameMap];
    return map[propertyName]?:propertyName;
}

+ (JRActivatedProperty *)activityWithPropertyName:(NSString *)name inClass:(Class<JRPersistent>)aClass {
    NSMutableDictionary<NSString *, JRActivatedProperty *> *dict = objc_getAssociatedObject(aClass, _cmd);
    if (!dict) {
        NSArray<JRActivatedProperty *> *aps = [aClass jr_activatedProperties];
        dict = [NSMutableDictionary dictionary];
        [aps enumerateObjectsUsingBlock:^(JRActivatedProperty * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            dict[obj.propertyName] = obj;
        }];
        objc_setAssociatedObject(aClass, _cmd, dict, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return dict[name];
}

+ (NSString *)getPrimaryKeyByName:(NSString *)name inClass:(Class<JRPersistent>)aClass {
    if (isID(name)) {
        return DBIDKey;
    }
    return [self activityWithPropertyName:name inClass:aClass].dataBaseName;
}

@end
