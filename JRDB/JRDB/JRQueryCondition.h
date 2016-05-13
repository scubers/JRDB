//
//  JRQueryCondition.h
//  JRDB
//
//  Created by JMacMini on 16/5/11.
//  Copyright © 2016年 Jrwong. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, JRQueryConditionType) {
    JRQueryConditionTypeAnd = 1,
    JRQueryConditionTypeOr,
};

@interface JRQueryCondition : NSObject

@property (nonatomic, copy, readonly  ) NSString             *condition;
@property (nonatomic, copy, readonly  ) NSArray              *args;
@property (nonatomic, assign, readonly) JRQueryConditionType type;

/**
 *  条件查询需要的condition
 *
 *  @param condition @"name = ?"
 *  @param args      @[@"11"]
 *  @param type      'and' or 'or'
 *
 *  @return instancetype
 */
+ (instancetype)condition:(NSString *)condition args:(NSArray *)args type:(JRQueryConditionType)type;

@end
