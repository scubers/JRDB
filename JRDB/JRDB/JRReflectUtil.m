//
//  JRReflectUtil.m
//  JRDB
//
//  Created by JMacMini on 16/5/10.
//  Copyright © 2016年 Jrwong. All rights reserved.
//

#import "JRReflectUtil.h"
#import "Person.h"

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

+ (NSArray *)ivarAndEncode4Clazz:(Class)clazz {
    NSMutableArray *list = [NSMutableArray array];
    
    unsigned int outCount;
    
    objc_property_t *prop = class_copyPropertyList(clazz, &outCount);
    for (int i = 0; i < outCount; i++) {
        objc_property_t p = prop[i];
        unsigned int c;
        objc_property_attribute_t *attributes = property_copyAttributeList(p, &c);
        
        NSString *name = [NSString stringWithUTF8String:attributes[c-1].value];
        NSString *encode = [NSString stringWithUTF8String:attributes[0].value];
        
        [list addObject:@{name : encode}];
    }
    
//        Ivar ivar = class_getInstanceVariable([Person class], attributes[c-1].value);
//        if ([encode isEqualToString:[NSString stringWithUTF8String:@encode(int)]]) {
////                int ret = (int*)((unsigned char *)((__bridge void *)(p)) + ivar_getOffset(ivar));
//            int ret = (int *)((void *)(p) + ivar_getOffset(ivar));
//        }
//        else if ([encode isEqualToString:[NSString stringWithUTF8String:@encode(unsigned int)]]) {
//            unsigned int ret = (unsigned int *)((void *)(p) + ivar_getOffset(ivar));
//        }
    return list;
}


@end
