//
//  JRSql.h
//  JRDB
//
//  Created by 王俊仁 on 16/6/13.
//  Copyright © 2016年 Jrwong. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JRSql : NSObject

@property (nonatomic, nullable, readonly) NSString *sqlString;
@property (nonatomic, nullable, readonly) NSMutableArray *args;

+ (instancetype _Nonnull)sql:(NSString * _Nonnull)sql args:(NSArray * _Nullable)args;

@end
