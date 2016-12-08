//
//  JRDBResult.h
//  JRDB
//
//  Created by J on 16/8/18.
//  Copyright © 2016年 Jrwong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JRPersistent.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, JRDBResultType) {
    JRDBResultType_flag = 1,
    JRDBResultType_count = 2,
    JRDBResultType_list = 3,
    JRDBResultType_object = 4,
};

@interface JRDBResult : NSObject

+ (instancetype)resultWithBool:(BOOL)flag;
+ (instancetype)resultWithArray:(NSArray<id<JRPersistent>> *)array;
+ (instancetype)resultWithObject:(id<JRPersistent>)object;
+ (instancetype)resultWithCount:(NSUInteger)count;


@property (nonatomic, assign, readonly) JRDBResultType type;
@property (nonatomic, assign, readonly) BOOL flag;
@property (nonatomic, assign, readonly) NSUInteger count;
@property (nonatomic, strong, readonly) NSArray<id<JRPersistent>> *list;
@property (nonatomic, strong, readonly, nullable) id<JRPersistent> object;


@end

NS_ASSUME_NONNULL_END
