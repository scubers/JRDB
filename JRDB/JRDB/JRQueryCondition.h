//
//  JRQueryCondition.h
//  JRDB
//
//  Created by JMacMini on 16/5/11.
//  Copyright © 2016年 Jrwong. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, JRQueryConditionType) {
    JRQueryConditionTypeAnd = 1,
    JRQueryConditionTypeOr,
};

@interface JRQueryCondition : NSObject

@property (nonatomic, copy, readonly  ) NSString             * condition;
@property (nonatomic, copy, readonly, nullable) NSArray              *args;
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
+ (instancetype)condition:(NSString *)condition args:(NSArray * _Nullable)args type:(JRQueryConditionType)type;

/**
 *  条件查询需要的condition
 *
 *  @param type      'and' or 'or'
 *  @param condition 【_name = ?】 , name ；可变参数需要为id类型，参数结尾添加nil
 *
 *  @return instancetype
 */
+ (instancetype)type:(JRQueryConditionType)type condition:(NSString *)condition, ...;


@end

NS_ASSUME_NONNULL_END
