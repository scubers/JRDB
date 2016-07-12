//
//  JRFMDBResultSetHandler+Chain.h
//  JRDB
//
//  Created by JMacMini on 16/7/12.
//  Copyright © 2016年 Jrwong. All rights reserved.
//

#import "JRFMDBResultSetHandler.h"

@class JRDBChain;

@interface JRFMDBResultSetHandler (Chain)

+ (id _Nonnull)handleResultSet:(FMResultSet * _Nonnull)resultSet forChain:(JRDBChain * _Nonnull)chain;


@end
