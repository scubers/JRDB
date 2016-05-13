//
//  JRFMDBResultSetHandler.h
//  JRDB
//
//  Created by JMacMini on 16/5/11.
//  Copyright © 2016年 Jrwong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JRPersistent.h"

@class FMResultSet;

@interface JRFMDBResultSetHandler : NSObject

+ (NSArray<id<JRPersistent>> * _Nonnull)handleResultSet:(FMResultSet * _Nonnull)resultSet forClazz:(Class<JRPersistent> _Nonnull)clazz;

@end
