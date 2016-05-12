//
//  NSObject+JRDB.m
//  JRDB
//
//  Created by JMacMini on 16/5/10.
//  Copyright © 2016年 Jrwong. All rights reserved.
//

#import "NSObject+JRDB.h"
#import <objc/runtime.h>

const NSString *JRDB_IDKEY = @"JRDB_IDKEY";

@implementation NSObject (JRDB)

+ (NSArray *)jr_excludePropertyNames {
    return nil;
}

- (void)setID:(NSString *)ID {
    objc_setAssociatedObject(self, &JRDB_IDKEY, ID, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSString *)ID {
    return objc_getAssociatedObject(self, &JRDB_IDKEY);
}

@end
