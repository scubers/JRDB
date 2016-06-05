//
//  OBJCMethod.h
//  JRDB
//
//  Created by 王俊仁 on 16/6/5.
//  Copyright © 2016年 Jrwong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

@interface OBJCMethod : NSObject

+ (instancetype)method:(Method)method;

@property (nonatomic, readonly, copy) NSString *typeEncoding;
@property (nonatomic, readonly, copy) NSString *returnType;

@property (nonatomic, readonly, assign) SEL selector;

- (void *)sendToTarget:(id)target, ...;

@end
