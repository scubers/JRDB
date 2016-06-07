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

@implementation JRReflectUtil

+ (NSDictionary<NSString *, NSString *> *)propNameAndEncode4Clazz:(Class)clazz {
    NSString *className = [NSString stringWithUTF8String:class_getName(clazz)];
    if ([className isEqualToString:@"NSObject"]) {
        return nil;
    } else {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [[clazz objc_properties] enumerateObjectsUsingBlock:^(OBJCProperty * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            dict[obj.ivarName] = obj.typeEncoding;
        }];
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

@end
