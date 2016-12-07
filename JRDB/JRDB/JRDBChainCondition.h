//
//  JRDBChainCondition.h
//  JRDB
//
//  Created by J on 2016/12/7.
//  Copyright © 2016年 Jrwong. All rights reserved.
//

#import <Foundation/Foundation.h>

// J_Select(Person)
// .and.key(name).eq("name")
// .and.key(name1).nq("name")
// .and.key(name2).like("name")
// .or.key("age").gt(10)
// .or.key("number").lt(11)
// .list;
//

@class JRDBChain;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, JRDBChainConditionType) {
    JRDBChainConditionType_And,
    JRDBChainConditionType_Or,
};

typedef NS_ENUM(NSInteger, JRDBChainConditionOperator) {
    JRDBChainConditionOperator_Equal,
    JRDBChainConditionOperator_NotEqual,
    JRDBChainConditionOperator_Like,
    JRDBChainConditionOperator_GreaterThan,
    JRDBChainConditionOperator_GreaterThanOrEqual,
    JRDBChainConditionOperator_LessThan,
    JRDBChainConditionOperator_LessThanOrEqual,
};

@interface JRDBChainCondition : NSObject


@property (nonatomic, weak  , readonly) JRDBChain *chain;
@property (nonatomic, assign, readonly) JRDBChainConditionType type;
@property (nonatomic, assign, readonly) JRDBChainConditionOperator operator;

@property (nonatomic, strong, readonly) NSString *propName;
@property (nonatomic, strong, readonly) id param;


+ (instancetype)chainConditionWithChain:(JRDBChain *)chain type:(JRDBChainConditionType)type;

/** property name */
- (JRDBChainCondition *(^)(NSString *prop))key;

/** equal operator */
- (JRDBChain *(^)(id _Nullable param))eq;

/** not equal operator */
- (JRDBChain *(^)(id _Nullable param))nq;

/** like operator */
- (JRDBChain *(^)(id param))like;

/** greater than operator */
- (JRDBChain *(^)(id param))gt;
/** greater than or equal operator */
- (JRDBChain *(^)(id param))gtOrEq;

/** less than operator */
- (JRDBChain *(^)(id param))lt;
/** less than or equal operator */
- (JRDBChain *(^)(id param))ltOrEq;

- (NSString *)operatorString;
- (NSString *)typeString;


@end

NS_ASSUME_NONNULL_END
