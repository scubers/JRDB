//
//  JRSqlGenerator.h
//  JRDB
//
//  Created by JMacMini on 16/5/10.
//  Copyright © 2016年 Jrwong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JRPersistent.h"

@class FMDatabase, JRQueryCondition;

typedef enum {
    DBTypeNull = 1,
    DBTypeInteger,
    DBTypeReal,
    DBTypeText,
    DBTypeBlob
//    NULL，值是NULL
//    l  INTEGER，值是有符号整形，根据值的大小以1,2,3,4,6或8字节存放
//    l  REAL，值是浮点型值，以8字节IEEE浮点数存放
//    l  TEXT，值是文本字符串，使用数据库编码（UTF-8，UTF-16BE或者UTF-16LE）存放
//    l  BLOB
} DBType;

@interface JRSqlGenerator : NSObject

+ (NSString *)createTableSql4Clazz:(Class<JRPersistent>)clazz;
+ (NSString *)updateTableSql4Clazz:(Class<JRPersistent>)clazz inDB:(FMDatabase *)db;
+ (NSString *)deleteTableSql4Clazz:(Class<JRPersistent>)clazz;

/**
 *  返回占位符的sql insert into tablename values (name= ? , name2 = ?,)
 */
+ (NSString *)sql4Insert:(id<JRPersistent>)obj args:(NSArray **)args;
/**
 *  返回占位符的sql update tablename set name = ?, name2 = ? where ID = ?
 *  columns 需要更新的列，传nil则全部更新
 */
+ (NSString *)sql4Update:(id<JRPersistent>)obj columns:(NSArray<NSString *> *)columns args:(NSArray **)args;;
/**
 *  返回占位符的sql delete from tablename where ID = ?
 */
+ (NSString *)sql4Delete:(id<JRPersistent>)obj;

/**
 *  根据id获取对象
 *
 *  @param clazz 对象类
 *
 *  @return sql
 */
+ (NSString *)sql4GetByIdWithClazz:(Class<JRPersistent>)clazz;

/**
 *  查找某个类的所有对象
 *
 *  @param clazz 类
 *  @param clazz 排序字段
 *
 *  @return sql
 */
+ (NSString *)sql4FindAll:(Class<JRPersistent>)clazz orderby:(NSString *)orderby isDesc:(BOOL)isDesc;

/**
 *  根据条件查询
 *
 *  @param conditions 条件数组
 *  @param clazz      类
 *  @param isDesc     是否倒序
 *
 *  @return sql
 */
+ (NSString *)sql4FindByConditions:(NSArray<JRQueryCondition *> *)conditions clazz:(Class<JRPersistent>)clazz isDesc:(BOOL)isDesc;

@end
