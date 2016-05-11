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
    JRQueryConditionTypeGroupBy, // 只需要字段名即可
    JRQueryConditionTypeOrderBy, // 只需要字段名即可
    JRQueryConditionTypeLimit    // limit 0,3
};

@interface JRQueryCondition : NSObject

@property (nonatomic, copy, readonly) NSString *condition;
@property (nonatomic, assign, readonly) JRQueryConditionType type;

+ (instancetype)condition:(NSString *)condition type:(JRQueryConditionType)type;

@end
