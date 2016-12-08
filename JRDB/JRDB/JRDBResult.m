//
//  JRDBResult.m
//  JRDB
//
//  Created by J on 16/8/18.
//  Copyright © 2016年 Jrwong. All rights reserved.
//

#import "JRDBResult.h"


@implementation JRDBResult

@synthesize flag = _flag;
@synthesize count = _count;
@synthesize list = _list;
@synthesize object = _object;


+ (instancetype)resultWithBool:(BOOL)flag {
    JRDBResult *result = [[self alloc] init];
    result->_type = JRDBResultType_flag;
    result->_flag = flag;
    return result;
}

+ (instancetype)resultWithCount:(NSUInteger)count {
    JRDBResult *result = [[self alloc] init];
    result->_type = JRDBResultType_count;
    result->_count = count;
    return result;
}

+ (instancetype)resultWithArray:(NSArray<JRPersistent> *)array {
    JRDBResult *result = [[self alloc] init];
    result->_type = JRDBResultType_list;
    result->_list = array;
    return result;
}

+ (instancetype)resultWithObject:(id<JRPersistent>)object {
    JRDBResult *result = [[self alloc] init];
    result->_type = JRDBResultType_object;
    result->_object = object;
    return result;
}

- (BOOL)flag {
    if (self.type == JRDBResultType_flag) {
        return _flag;
    }
    [self assertNO];
    return NO;
}

- (NSUInteger)count {
    if (self.type == JRDBResultType_count) {
        return _count;
    }
    [self assertNO];
    return 0;
}

- (NSArray<id<JRPersistent>> *)list {
    if (self.type == JRDBResultType_list) {
        return _list;
    }
    [self assertNO];
    return nil;
}

- (id<JRPersistent>)object {
    if (self.type == JRDBResultType_object) {
        return _object;
    }
    [self assertNO];
    return nil;
}

- (void)assertNO {
    switch (self.type) {
        case JRDBResultType_flag: NSAssert(NO, @"type error, you should use .flag");
        case JRDBResultType_count:NSAssert(NO, @"type error, you should use .count");
        case JRDBResultType_list:NSAssert(NO, @"type error, you should use .list");
        case JRDBResultType_object:NSAssert(NO, @"type error, you should use .object");
    }
}

@end
