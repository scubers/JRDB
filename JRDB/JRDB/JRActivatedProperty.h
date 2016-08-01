//
//  JRActivatedProperty.h
//  JRDB
//
//  Created by 王俊仁 on 16/6/13.
//  Copyright © 2016年 Jrwong. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, JRRelation) {
    JRRelationNormal = 1,   ///< 普通字段
    JRRelationOneToOne,     ///< 一对一字段
    JRRelationOneToMany,    ///< 一对多字段
    JRRelationChildren,     ///< 子节点字段
} ;

@interface JRActivatedProperty : NSObject

@property (nonatomic, assign, readonly) JRRelation relateionShip;
@property (nonatomic, nonnull, copy   ) NSString   *name;
@property (nonatomic, nonnull, copy   ) NSString   *dataBaseName;
@property (nonatomic, nonnull, copy   ) NSString   *dataBaseType;
@property (nonatomic, nonnull, copy   ) NSString   *typeEncode;
@property (nonatomic, nonnull, strong ) Class      clazz;

+ (instancetype _Nonnull)property:(NSString * _Nonnull)name relationShip:(JRRelation)relationShip;

@end
