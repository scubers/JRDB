//
//  JRActivatedProperty.h
//  JRDB
//
//  Created by 王俊仁 on 16/6/13.
//  Copyright © 2016年 Jrwong. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, JRRelation) {
    JRRelationNormal = 1,   ///< 普通字段
    JRRelationOneToOne,     ///< 一对一字段
    JRRelationOneToMany,    ///< 一对多字段
    JRRelationChildren,     ///< 子节点字段
} ;

@interface JRActivatedProperty : NSObject

@property (nonatomic, assign, readonly) JRRelation relateionShip;
@property (nonatomic, copy   ) NSString   *propertyName;
@property (nonatomic, copy   ) NSString   *ivarName;
@property (nonatomic, copy   ) NSString   *dataBaseName;
@property (nonatomic, copy   ) NSString   *dataBaseType;
@property (nonatomic, copy   ) NSString   *typeEncode;
@property (nonatomic, strong ) Class      clazz;///< 一对一，一对多，子节点对应的类

+ (instancetype)property:(NSString *)name relationShip:(JRRelation)relationShip;

@end

NS_ASSUME_NONNULL_END
