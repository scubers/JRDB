//
//  JRPersistentUtil.h
//  JRDB
//
//  Created by 王俊仁 on 2016/12/7.
//  Copyright © 2016年 Jrwong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JRPersistent.h"

@class JRActivatedProperty;

NS_ASSUME_NONNULL_BEGIN

@interface JRPersistentUtil : NSObject


/**
 返回所有激活状态的属性，包括其父类

 @param aClass aClass description
 */
+ (NSArray<JRActivatedProperty *> *)allPropertesForClass:(Class<JRPersistent>)aClass;

@end

NS_ASSUME_NONNULL_END
