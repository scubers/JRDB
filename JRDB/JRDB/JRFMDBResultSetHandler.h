//
//  JRFMDBResultSetHandler.h
//  JRDB
//
//  Created by JMacMini on 16/5/11.
//  Copyright © 2016年 Jrwong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JRPersistent.h"
#import <FMDB.h>

@interface JRFMDBResultSetHandler : NSObject

+ (NSArray<id<JRPersistent>> *)handleResultSet:(FMResultSet *)resultSet forClazz:(Class<JRPersistent>)clazz;

@end
