//
//  JRFMDBResultSetHandler.h
//  JRDB
//
//  Created by JMacMini on 16/5/11.
//  Copyright © 2016年 Jrwong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JRPersistent.h"

@class FMResultSet, JRDBChain;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, RetDataType) {
    RetDataTypeInt = 1,
    RetDataTypeUnsignedInt,
    RetDataTypeLong,
    RetDataTypeLongLong,
    RetDataTypeUnsignedLong,
    RetDataTypeUnsignedLongLong,
    RetDataTypeDouble,
    RetDataTypeFloat,
    RetDataTypeString,
    
    RetDataTypeNSNumber,
    RetDataTypeNSData,
    RetDataTypeNSDate,
    
    RetDataTypeUnsupport
};

@interface JRFMDBResultSetHandler : NSObject

+ (NSArray<id<JRPersistent>> *)handleResultSet:(FMResultSet *)resultSet forClazz:(Class<JRPersistent>)clazz columns:(NSArray * _Nullable)columns;

@end



@interface JRFMDBResultSetHandler (Chain)


/**
 自定义查询使用，不会关联查询

 @param resultSet resultSet description
 @param chain chain description
 */
+ (id)handleResultSet:(FMResultSet *)resultSet forChain:(JRDBChain *)chain;

@end


NS_ASSUME_NONNULL_END
