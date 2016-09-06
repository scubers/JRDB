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

@interface JRSql : NSObject

@property (nonatomic, nullable, readonly) NSString *sqlString;
@property (nonatomic, nullable, readonly) NSMutableArray *args;

+ (instancetype _Nonnull)sql:(NSString * _Nonnull)sql args:(NSArray * _Nullable)args;

@end


void SqlLog(id _Nonnull sql);

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
+ (JRSql * _Nonnull)createTableSql4Clazz:(Class<JRPersistent> _Nonnull)clazz table:(NSString * _Nullable)table;

/**
 *  删表
 *
 *  @param clazz 对应的类
 *  @return sql
 */
+ (JRSql * _Nonnull)dropTableSql4Clazz:(Class<JRPersistent> _Nonnull)clazz table:(NSString * _Nullable)table;

/**
 *  因为sqlite不支持批量添加字段，只能返回多条语句，多次更新表
 *
 *  @param clazz 类
 *  @param db    数据库
 *
 *  @return sql数组
 */
+ (NSArray<JRSql *> * _Nonnull)updateTableSql4Clazz:(Class<JRPersistent> _Nonnull)clazz inDB:(FMDatabase * _Nonnull)db table:(NSString * _Nullable)table;

#pragma mark - insert

/**
 *  返回占位符的sql insert into tablename values (name= ? , name2 = ?,)
 */
+ (JRSql * _Nonnull)sql4Insert:(id<JRPersistent> _Nonnull)obj toDB:(FMDatabase * _Nonnull)db table:(NSString * _Nullable)table;

#pragma mark - update
/**
 *  返回占位符的sql update tablename set name = ?, name2 = ? where ID = ?
 *  columns 需要更新的列，传nil则全部更新
 */
+ (JRSql * _Nonnull)sql4Update:(id<JRPersistent> _Nonnull)obj
                       columns:(NSArray<NSString *> * _Nullable)columns
                          toDB:(FMDatabase * _Nonnull)db
                         table:(NSString * _Nullable)table;


#pragma mark - delete
/**
 *  返回占位符的sql delete from tablename where ID = ?
 */
+ (JRSql * _Nonnull)sql4Delete:(id<JRPersistent> _Nonnull)obj table:(NSString * _Nullable)table;

/**
 *  返回占位符的sql delete from tablename
 */
+ (JRSql * _Nonnull)sql4DeleteAll:(Class<JRPersistent> _Nonnull)clazz table:(NSString * _Nullable)table;


#pragma mark - query
/**
 *  根据ID （数据库主键）获取对象
 *
 *  @param clazz 对象类
 *
 *  @return sql
 */
+ (JRSql * _Nonnull)sql4GetByIDWithClazz:(Class<JRPersistent> _Nonnull)clazz ID:(NSString * _Nonnull)ID table:(NSString * _Nullable)table;


/**
 *  根据主键 （自定义主键）获取对象
 *
 *  @param clazz 对象类
 *
 *  @return sql
 */
+ (JRSql * _Nonnull)sql4GetByPrimaryKeyWithClazz:(Class<JRPersistent> _Nonnull)clazz primaryKey:(id _Nonnull)primaryKey table:(NSString * _Nullable)table;

/**
 *  查找某个类的所有对象
 *
 *  @param clazz 类
 *  @param clazz 排序字段
 *
 *  @return sql
 */
+ (JRSql * _Nonnull)sql4FindAll:(Class<JRPersistent> _Nonnull)clazz orderby:(NSString * _Nullable)orderby isDesc:(BOOL)isDesc table:(NSString * _Nullable)table;

/**
 *  根据条件查询
 *
 *  @param conditions 条件数组
 *  @param clazz      类
 *  @param isDesc     是否倒序
 *
 *  @return sql
 */
+ (JRSql * _Nonnull)sql4FindByConditions:(NSArray<JRQueryCondition *> * _Nullable)conditions
                                   clazz:(Class<JRPersistent> _Nonnull)clazz
                                 groupBy:(NSString * _Nullable)groupBy
                                 orderBy:(NSString * _Nullable)orderBy
                                   limit:(NSString * _Nullable)limit
                                  isDesc:(BOOL)isDesc
                                   table:(NSString * _Nullable)table;
#pragma mark - conenience
+ (JRSql * _Nonnull)sql4CountByPrimaryKey:(id _Nonnull)pk clazz:(Class<JRPersistent> _Nonnull)clazz table:(NSString * _Nullable)table;
+ (JRSql * _Nonnull)sql4CountByID:(NSString * _Nonnull)ID clazz:(Class<JRPersistent> _Nonnull)clazz table:(NSString * _Nullable)table;

+ (JRSql * _Nonnull)sql4GetColumns:(NSArray<NSString *> * _Nullable)columns
                      byConditions:(NSArray<JRQueryCondition *> * _Nullable)conditions
                             clazz:(Class<JRPersistent> _Nonnull)clazz
                           groupBy:(NSString * _Nullable)groupBy
                           orderBy:(NSString * _Nullable)orderBy
                             limit:(NSString * _Nullable)limit
                            isDesc:(BOOL)isDesc
                             table:(NSString * _Nullable)table;

@end


@interface JRSqlGenerator (Chain)

+ (JRSql * _Nonnull)sql4ChainCustomizedSelect:(JRDBChain * _Nonnull)chain;
+ (JRSql * _Nonnull)sql4GetColumns:(NSArray<NSString *> * _Nullable)columns forChain:(JRDBChain * _Nonnull)chain;
+ (JRSql * _Nonnull)sql4Chain:(JRDBChain * _Nonnull)chain;

@end