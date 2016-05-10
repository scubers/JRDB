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
    Person *p = [[Person alloc] init];
    p.a_int = 1;
    p.b_unsigned_int = 2;
    p.c_long = 3;
    p.d_long_long = 4;
    p.e_unsigned_long = 5;
    p.f_unsigned_long_long = 6;
    p.g_float = 7.0;
    p.h_double = 8.0;
    p.i_string = @"9";
    p.j_number = @10;
    p.k_data = [NSData data];
    p.l_date = [NSDate date];
    
    NSLog(@"%@", [p valueForKey:@"g_float"]);
    
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
