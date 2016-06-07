//
//  NSObject+Reflect.m
//  JRDB
//
//  Created by 王俊仁 on 16/6/5.
//  Copyright © 2016年 Jrwong. All rights reserved.
//

#import "NSObject+Reflect.h"
#import <objc/runtime.h>
#import "OBJCProperty.h"
#import "OBJCMethod.h"

@implementation NSObject (Reflect)

+ (NSString *)fullClazzName {
    return NSStringFromClass(self);
}

+ (NSString *)shortClazzName {
    NSString *name = [self fullClazzName];
    if ([name rangeOfString:@"."].length) {
        name = [name substringFromIndex:[name rangeOfString:@"."].location + 1];
    }
    return name;
}

+ (NSArray<OBJCProperty *> *)objc_properties {
    unsigned int outCount;
    objc_property_t *props = class_copyPropertyList([self class], &outCount);
    NSMutableArray *array = [NSMutableArray array];
    for (int i = 0; i < outCount; i++) {
        [array addObject:[OBJCProperty prop:props[i]]];
    }
    return array;
}

+ (OBJCProperty *)objcPropertyWithName:(NSString *)name {
    __block OBJCProperty *p = nil;
    [[self objc_properties] enumerateObjectsUsingBlock:^(OBJCProperty * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.name isEqualToString:name] || [obj.ivarName isEqualToString:name]) {
            p = obj;
            *stop = YES;
        }
    }];
    return p;
}

+ (NSArray<OBJCMethod *> *)objc_methods {
    unsigned int outCount;
    Method *methods = class_copyMethodList(self, &outCount);

    NSMutableArray *array = [NSMutableArray array];
    for (int i = 0; i < outCount; i++) {
        [array addObject:[OBJCMethod method:methods[i]]];
    }
    return array;
}

+ (OBJCMethod *)objcMethodWithSel:(SEL)selector {
    __block OBJCMethod *m = nil;
    [[self objc_methods] enumerateObjectsUsingBlock:^(OBJCMethod * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.selector == selector) {
            m = obj;
            *stop = YES;
        }
    }];
    return m;
}

+ (void)objc_exchangeMethod:(SEL)selector withMethod:(SEL)aSelector {
    Method m1 = class_getInstanceMethod(self, selector);
    Method m2 = class_getInstanceMethod(self, aSelector);
    method_exchangeImplementations(m1, m2);
}

- (NSDictionary<NSString *,id> *)jr_toDict {
    NSArray<OBJCProperty *> *props = [[self class] objc_properties];
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [props enumerateObjectsUsingBlock:^(OBJCProperty * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        id value = [self valueForKey:obj.name];
        dict[obj.name] = value ? value : [NSNull null];
    }];
    return [dict copy];
}

@end
