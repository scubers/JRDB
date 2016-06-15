//
//  JRSql.m
//  JRDB
//
//  Created by 王俊仁 on 16/6/13.
//  Copyright © 2016年 Jrwong. All rights reserved.
//

#import "JRSql.h"

@implementation JRSql

@synthesize sqlString = _sqlString;
@synthesize args = _args;

+ (instancetype)sql:(NSString *)sql args:(NSArray *)args {
    JRSql *jrsql = [[self alloc] init];
    jrsql->_sqlString = sql;
    jrsql->_args = [args mutableCopy];
    return jrsql;
}

- (NSMutableArray *)args {
    if (!_args) {
        _args = [NSMutableArray array];
    }
    return _args;
}

- (NSString *)description {
    return _sqlString ? _sqlString : @"";
}

@end
