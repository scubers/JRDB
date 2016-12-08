//
//  JRSqlGenerator.h
//  JRDB
//
//  Created by JMacMini on 16/5/10.
//  Copyright © 2016年 Jrwong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JRPersistent.h"
#import "JRPersistentHandler.h"

NS_ASSUME_NONNULL_BEGIN

@interface JRSql : NSObject

@property (nonatomic, nullable, readonly) NSString *sqlString;
@property (nonatomic, nullable, readonly) NSMutableArray *args;

+ (instancetype)sql:(NSString *)sql args:(NSArray * _Nullable)args;

@end

typedef NS_ENUM(NSInteger, DBType) {
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
} ;

@interface JRSqlGenerator : NSObject

#pragma mark - table operation
/**
 *  建表
 *
 *  @param clazz 对应的类
 *  @return sql
 */
+ (JRSql *)createTableSql4Clazz:(Class<JRPersistent>)clazz table:(NSString * _Nullable)table;

/**
 *  删表
 *
 *  @param clazz 对应的类
 *  @return sql
 */
+ (JRSql *)dropTableSql4Clazz:(Class<JRPersistent>)clazz table:(NSString * _Nullable)table;

/**
 *  因为sqlite不支持批量添加字段，只能返回多条语句，多次更新表
 *
 *  @param clazz 类
 *  @param db    数据库
 *
 *  @return sql数组
 */
+ (NSArray<JRSql *> *)updateTableSql4Clazz:(Class<JRPersistent>)clazz inDB:(id<JRPersistentHandler>)db table:(NSString * _Nullable)table;

#pragma mark - insert

/**
 *  返回占位符的sql insert into tablename values (name= ? , name2 = ?,)
 */
+ (JRSql *)sql4Insert:(id<JRPersistent>)obj toDB:(id<JRPersistentHandler>)db table:(NSString * _Nullable)table;

#pragma mark - update
/**
 *  返回占位符的sql update tablename set name = ?, name2 = ? where ID = ?
 *  columns 需要更新的列，传nil则全部更新
 */
+ (JRSql *)sql4Update:(id<JRPersistent>)obj
              columns:(NSArray<NSString *> * _Nullable)columns
                 toDB:(id<JRPersistentHandler>)db
                table:(NSString * _Nullable)table;


#pragma mark - delete
/**
 *  返回占位符的sql delete from tablename where ID = ?
 */
+ (JRSql *)sql4Delete:(id<JRPersistent>)obj table:(NSString * _Nullable)table;

/**
 *  返回占位符的sql delete from tablename
 */
+ (JRSql *)sql4DeleteAll:(Class<JRPersistent>)clazz table:(NSString * _Nullable)table;


#pragma mark - query
/**
 *  根据ID （数据库主键）获取对象
 *
 *  @param clazz 对象类
 *
 *  @return sql
 */
+ (JRSql *)sql4GetByIDWithClazz:(Class<JRPersistent>)clazz ID:(NSString *)ID table:(NSString * _Nullable)table;


/**
 *  根据主键 （自定义主键）获取对象
 *
 *  @param clazz 对象类
 *
 *  @return sql
 */
+ (JRSql *)sql4GetByPrimaryKeyWithClazz:(Class<JRPersistent>)clazz primaryKey:(id)primaryKey table:(NSString * _Nullable)table;

/**
 *  查找某个类的所有对象
 *
 *  @param clazz 类
 *  @param clazz 排序字段
 *
 *  @return sql
 */
+ (JRSql *)sql4FindAll:(Class<JRPersistent>)clazz orderby:(NSString * _Nullable)orderby isDesc:(BOOL)isDesc table:(NSString * _Nullable)table;

#pragma mark - conenience

+ (JRSql *)sql4CountByPrimaryKey:(id)pk clazz:(Class<JRPersistent>)clazz table:(NSString * _Nullable)table;
+ (JRSql *)sql4CountByID:(NSString *)ID clazz:(Class<JRPersistent>)clazz table:(NSString * _Nullable)table;


/**
 根据条件查询

 @param columns 要查找的列
 @param conditions where 语句
 @param params where 语句的参数
 @param clazz clazz description
 @param groupBy groupBy description
 @param orderBy orderBy description
 @param limit limit description
 @param isDesc isDesc description
 @param table table description
 */
+ (JRSql *)sql4GetColumns:(NSArray<NSString *> * _Nullable)columns
              byCondition:(NSString * _Nullable)condition
                   params:(NSArray * _Nullable)params
                    clazz:(Class<JRPersistent>)clazz
                  groupBy:(NSString * _Nullable)groupBy
                  orderBy:(NSString * _Nullable)orderBy
                    limit:(NSString * _Nullable)limit
                   isDesc:(BOOL)isDesc
                    table:(NSString * _Nullable)table;

@end


@interface JRSqlGenerator (Chain)

+ (JRSql *)sql4Chain:(JRDBChain *)chain;

@end

NS_ASSUME_NONNULL_END
