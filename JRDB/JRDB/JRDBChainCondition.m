//
//  JRDBChainCondition.m
//  JRDB
//
//  Created by J on 2016/12/7.
//  Copyright © 2016年 Jrwong. All rights reserved.
//

#import "JRDBChainCondition.h"

@implementation JRDBChainCondition

+ (instancetype)chainConditionWithChain:(JRDBChain *)chain type:(JRDBChainConditionType)type {
    JRDBChainCondition *con = [JRDBChainCondition new];
    con->_chain = chain;
    con->_type = type;
    return con;
}

- (JRDBChainCondition * _Nonnull (^)(NSString * _Nonnull))key {
    return ^JRDBChainCondition *(NSString *key) {
        self->_propName = key;
        return self;
    };
}

- (JRDBChain *(^)(id param))eq {
    return ^JRDBChain *(id param) {
        self->_param = param;
        self->_operator = JRDBChainConditionOperator_Equal;
        return self.chain;
    };
}

- (JRDBChain *(^)(id param))nq  {
    return ^JRDBChain *(id param) {
        self->_param = param;
        self->_operator = JRDBChainConditionOperator_NotEqual;
        return self.chain;
    };
}

- (JRDBChain *(^)(id param))like {
    return ^JRDBChain *(id param) {
        self->_param = param;
        self->_operator = JRDBChainConditionOperator_Like;
        return self.chain;
    };
}

- (JRDBChain * _Nonnull (^)(id _Nonnull))gt {
    return ^JRDBChain *(id param) {
        self->_param = param;
        self->_operator = JRDBChainConditionOperator_GreaterThan;
        return self.chain;
    };
}

- (JRDBChain * _Nonnull (^)(id _Nonnull))gtOrEq {
    return ^JRDBChain *(id param) {
        self->_param = param;
        self->_operator = JRDBChainConditionOperator_GreaterThanOrEqual;
        return self.chain;
    };
}

- (JRDBChain * _Nonnull (^)(id _Nonnull))lt {
    return ^JRDBChain *(id param) {
        self->_param = param;
        self->_operator = JRDBChainConditionOperator_LessThan;
        return self.chain;
    };
}

- (JRDBChain * _Nonnull (^)(id _Nonnull))ltOrEq {
    return ^JRDBChain *(id param) {
        self->_param = param;
        self->_operator = JRDBChainConditionOperator_LessThanOrEqual;
        return self.chain;
    };
}

- (NSString *)typeString {
    return _type == JRDBChainConditionType_And ? @"and" : @"or";
}

- (NSString *)operatorString {
    switch (_operator) {
        case JRDBChainConditionOperator_LessThan:return @"<";
        case JRDBChainConditionOperator_LessThanOrEqual:return @"<=";
        case JRDBChainConditionOperator_GreaterThan:return @">";
        case JRDBChainConditionOperator_GreaterThanOrEqual:return @">=";
        case JRDBChainConditionOperator_Like:return @"like";
        case JRDBChainConditionOperator_NotEqual:return @"<>";
        case JRDBChainConditionOperator_Equal:return @"=";
    }
    return nil;
}

@end
