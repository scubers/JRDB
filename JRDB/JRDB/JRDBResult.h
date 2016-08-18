//
//  JRDBResult.h
//  JRDB
//
//  Created by J on 16/8/18.
//  Copyright © 2016年 Jrwong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JRPersistent.h"

typedef NS_ENUM(NSInteger, JRDBResultType) {
    JRDBResultType_flag = 1,
    JRDBResultType_count = 2,
    JRDBResultType_list = 3,
    JRDBResultType_object = 4,
};

@interface JRDBResult : NSObject

+ (instancetype _Nonnull)resultWithBool:(BOOL)flag;
+ (instancetype _Nonnull)resultWithArray:(NSArray<JRPersistent> * _Nonnull)array;
+ (instancetype _Nonnull)resultWithObject:(id<JRPersistent> _Nonnull)object;
+ (instancetype _Nonnull)resultWithCount:(NSUInteger)count;


@property (nonatomic, assign, readonly) JRDBResultType type;
@property (nonatomic, assign, readonly) BOOL flag;
@property (nonatomic, assign, readonly) NSUInteger count;
@property (nonatomic, strong, readonly, nonnull) NSArray<JRPersistent> *list;
@property (nonatomic, strong, readonly, nullable) id<JRPersistent> object;


@end
