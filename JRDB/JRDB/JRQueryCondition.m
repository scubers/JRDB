//
//  JRQueryCondition.m
//  JRDB
//
//  Created by JMacMini on 16/5/11.
//  Copyright © 2016年 Jrwong. All rights reserved.
//

#import "JRQueryCondition.h"

@interface JRQueryCondition()
{
    NSString *_condition;
    NSArray *_args;
    JRQueryConditionType _type;
}

@end

@implementation JRQueryCondition

+ (instancetype)condition:(NSString *)condition args:(NSArray *)args type:(JRQueryConditionType)type {
    JRQueryCondition *condi = [[JRQueryCondition alloc] init];
    condi->_condition = condition;
    condi->_type = type;
    condi->_args = args;
    return condi;
}

+ (instancetype)type:(JRQueryConditionType)type condition:(NSString *)condition, ... {
    JRQueryCondition *condi = [[JRQueryCondition alloc] init];
    NSMutableArray *args = [NSMutableArray array];
    va_list ap;
    va_start(ap, condition);
    id arg;
    while( (arg = va_arg(ap,id)) != NULL )
    {
        if ( arg ){  
            [args addObject:arg];
        }  
    }  
    va_end(ap);
    condi->_args = args;
    condi->_condition = condition;
    condi->_type = type;
    return condi;
}

@end
