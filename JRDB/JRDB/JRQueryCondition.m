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
    JRQueryConditionType _type;
}

@end

@implementation JRQueryCondition

+ (instancetype)condition:(NSString *)condition type:(JRQueryConditionType)type {
    JRQueryCondition *condi = [[JRQueryCondition alloc] init];
    condi->_condition = condition;
    condi->_type = type;
    return condi;
}

@end
