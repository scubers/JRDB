//
//  JRReflectUtil.m
//  JRDB
//
//  Created by JMacMini on 16/5/10.
//  Copyright © 2016年 Jrwong. All rights reserved.
//

#import "JRReflectUtil.h"

@implementation JRReflectUtil

+ (NSString *)fullClazzName:(Class)clazz {
    return NSStringFromClass(clazz);
}

+ (NSString *)shortClazzName:(Class)clazz {
    NSString *name = [self fullClazzName:clazz];
    if ([name rangeOfString:@"."].length) {
        name = [name substringFromIndex:[name rangeOfString:@"."].location + 1];
    }
    return name;
}

+ (NSString *)simpleIvarName:(NSString *)ivarName {
    NSString *name = ivarName;
    if ([name hasPrefix:@"_"]) {
        name = [name substringFromIndex:1];
    }
    return name;
}

+ (NSDictionary<NSString *, NSString *> *)ivarAndEncode4Clazz:(Class)clazz {
    NSString *className = [NSString stringWithUTF8String:class_getName(clazz)];
    if ([className isEqualToString:@"NSObject"]) {
        return nil;
    } else {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        unsigned int outCount;
        objc_property_t *prop = class_copyPropertyList(clazz, &outCount);
        for (int i = 0; i < outCount; i++) {
            objc_property_t p = prop[i];
            unsigned int c;
            objc_property_attribute_t *attributes = property_copyAttributeList(p, &c);
            NSString *name = [NSString stringWithUTF8String:attributes[c-1].value];
            NSString *encode = [NSString stringWithUTF8String:attributes[0].value];
            if (name.length) {
                dict[name] = encode;
            }
        }
        [dict addEntriesFromDictionary:[self ivarAndEncode4Clazz:class_getSuperclass(clazz)]];
        return dict;
    }
    
}

+ (const char *)typeEncoding4InstanceMethod:(SEL)selector inClazz:(Class)clazz {
    Method method = class_getInstanceMethod(clazz, selector);
    return method_getTypeEncoding(method);
}

+ (BOOL)checkClazz:(Class)clazz isConformsTo:(Protocol *)aProtocol {
    return class_conformsToProtocol(clazz, aProtocol);
}

@end
