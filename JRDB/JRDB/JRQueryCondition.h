//
//  JRQueryCondition.h
//  JRDB
//
//  Created by JMacMini on 16/5/11.
//  Copyright © 2016年 Jrwong. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    JRQueryConditionTypeAnd = 1,
    JRQueryConditionTypeOr,
    JRQueryConditionTypeGroupBy,
    JRQueryConditionTypeOrderBy,
    JRQueryConditionTypeLimit
} JRQueryConditionType;

@interface JRQueryCondition : NSObject

@property (nonatomic, copy, readonly) NSString *condition;
@property (nonatomic, assign, readonly) JRQueryConditionType type;

+ (instancetype)condition:(NSString *)condition type:(JRQueryConditionType)type;

@end
