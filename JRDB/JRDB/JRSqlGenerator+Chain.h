//
//  JRSqlGenerator+Chain.h
//  JRDB
//
//  Created by JMacMini on 16/7/11.
//  Copyright © 2016年 Jrwong. All rights reserved.
//

#import "JRSqlGenerator.h"

@class JRDBChain, JRSql;

@interface JRSqlGenerator (Chain)

+ (JRSql *)sql4Chain:(JRDBChain *)chain;
+ (JRSql *)sql4ChainInsert:(JRDBChain *)chain;
+ (JRSql *)sql4ChainUpdate:(JRDBChain *)chain;
+ (JRSql *)sql4ChainDelete:(JRDBChain *)chain;
+ (JRSql *)sql4ChainDeleteAll:(JRDBChain *)chain;
+ (JRSql *)sql4ChainSelect:(JRDBChain *)chain;
+ (JRSql *)sql4ChainCustomizedSelect:(JRDBChain *)chain;

@end
