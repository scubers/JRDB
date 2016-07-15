//
//  JRDBChain.h
//  JRDB
//
//  Created by JMacMini on 16/7/11.
//  Copyright © 2016年 Jrwong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JRPersistent.h"

/**
 
 c.Insert(p).Into(name).InDB(db).Recursive(YES).NowInMain(NO).Complete(^(BOOL success){})
 
 c.Update(p).Table(name).InDB(db).Recursive(YES).NowInMain(NO).Columns().Ignore().Complete(^(BOOL success){})
 
 c.Delete(p).From(name).InDB(db).Recursive(YES).NowInMain(NO).Complete(^(BOOL success){})
 
 c.DeleteAll(p.class).From(name).InDB(db).Recursive(YES).NowInMain(NO).Complete(^(BOOL success){})
 
 c.Select(p.class).From(name).InDB(db).Recursive(YES).Where(@"_age = ?").Params().Group().Order().limit().Desc(YES)
 
 */

#define jr_weak(object) __weak __typeof__(object) weak##_##object = object
#define jr_strong(object) __typeof__(object) object = weak##_##object

#define J_Select(...)  ([JRDBChain new].Select(__VA_ARGS__))

#define J_Insert(_arg_)         ([JRDBChain new].Insert(_JRToArray(_arg_)))
#define J_Update(_arg_)         ([JRDBChain new].Update(_JRToArray(_arg_)))
#define J_Delete(_arg_)         ([JRDBChain new].Delete(_JRToArray(_arg_)))
#define J_SaveOrUpdate(_arg_)   ([JRDBChain new].SaveOrUpdate(_JRToArray(_arg_)))

#define J_DeleteAll(_arg_)  ([JRDBChain new].DeleteAll(_arg_))

#define J_CreateTable(_arg_)    ([JRDBChain new].CreateTable(_arg_))
#define J_UpdateTable(_arg_)    ([JRDBChain new].UpdateTable(_arg_))
#define J_DropTable(_arg_)      ([JRDBChain new].DropTable(_arg_))
#define J_TruncateTable(_arg_)  ([JRDBChain new].TruncateTable(_arg_))

#define WhereJ(_arg_) Where(@#_arg_)
#define OrderJ(_arg_) Order(@#_arg_)
#define GroupJ(_arg_) Group(@#_arg_)

typedef enum {
    CInsert = 1,
    CUpdate,
    CDelete,
    CSaveOrUpdate,
    CDeleteAll,
    CSelect,
    CSelectCustomized,
    CSelectCount,
    
    CCreateTable,
    CUpdateTable,
    CDropTable,
    CTruncateTable,

} ChainOperation;

static NSString * const JRCount = @"_|-JRCount-|_";

@class FMDatabase, JRDBChain, JRQueryCondition;

typedef JRDBChain *(^InsertBlock)(NSArray<id<JRPersistent>> *array);
typedef JRDBChain *(^UpdateBlock)(NSArray<id<JRPersistent>> *array);
typedef JRDBChain *(^DeleteBlock)(NSArray<id<JRPersistent>> *array);

typedef JRDBChain *(^SaveOrUpdateBlock)(NSArray<id<JRPersistent>> *array);

typedef JRDBChain *(^SelectBlock)(id first, ...);


typedef JRDBChain *(^DeleteAllBlock)(Class<JRPersistent> clazz);

typedef JRDBChain *(^CreateTableBlock)(Class<JRPersistent> clazz);
typedef JRDBChain *(^UpdateTableBlock)(Class<JRPersistent> clazz);
typedef JRDBChain *(^DropTableBlock)(Class<JRPersistent> clazz);
typedef JRDBChain *(^TruncateTableBlock)(Class<JRPersistent> clazz);


#define BlockPropertyDeclare(_ownership_, _name_, _paramType_, _paramName_) \
@property(nonatomic,_ownership_,readonly)_paramType_ _paramName_;\
@property(nonatomic,copy,readonly)JRDBChain*(^_name_)(_paramType_ param);


#define ArrayPropertyDeclare(_ownership_, _name_, _paramType_, _paramName_) \
@property(nonatomic,_ownership_,readonly)_paramType_ _paramName_;\
@property(nonatomic,copy,readonly)JRDBChain*(^_name_)(id param, ...);


#define OperationBlockDeclare(_name_, _type_) \
@property(nonatomic,copy,readonly)_type_ _name_;

static inline NSArray * _JRToArray(id arg) {
    if (!arg) NSLog(@"warning: _JRBoxValue should not pass a nil value");
    return [arg isKindOfClass:[NSArray class]] ? arg : arg ? @[arg] : @[];
}

struct JRLimit {
    long long start;
    long long length;
};
typedef struct JRLimit JRLimit;

@interface JRDBChain : NSObject

@property (nonatomic, strong, readonly) id<JRPersistent>          target;///< obj对象
@property (nonatomic, strong, readonly) Class<JRPersistent>       targetClazz; ///< obj array，
@property (nonatomic, strong, readonly) NSArray<id<JRPersistent>> *targetArray; ///< clazz，


@property (nonatomic, assign, readonly) ChainOperation   operation;///< 操作类型
@property (nonatomic, strong, readonly) NSString         *tableName;///< 被指定的表明

@property (nonatomic, strong, readonly) NSArray<JRQueryCondition *> *queryCondition; ///< 根据where语句生成的查询条件
@property (nonatomic, strong, readonly) NSArray<NSString*> *selectColumns;///< 自定义select时的columns

- (id)exe:(JRDBChainComplete)complete;

@property (nonatomic, copy) JRDBChain *(^From)(id from);///< 接收Class类 或者 NSString表名

// value param
@property (nonatomic, strong, readonly) JRDBChain *(^Limit)(NSUInteger start, NSUInteger length);
@property (nonatomic, assign, readonly) JRLimit limitIn;
@property (nonatomic, strong, readonly) NSString *limitString;


BlockPropertyDeclare(strong, InDB, FMDatabase *, db);
BlockPropertyDeclare(strong, Order, NSString *, orderBy);
BlockPropertyDeclare(strong, Group, NSString *, groupBy);
BlockPropertyDeclare(strong, Where, NSString *, whereString);
BlockPropertyDeclare(assign, Recursive, BOOL, isRecursive);
BlockPropertyDeclare(assign, Sync, BOOL, isSync);
BlockPropertyDeclare(assign, Trasaction, BOOL, useTransaction);
BlockPropertyDeclare(assign, Desc, BOOL, isDesc);
BlockPropertyDeclare(assign, Cache, BOOL, useCache);
BlockPropertyDeclare(copy, Complete, JRDBChainComplete, completeBlock);

// array param
ArrayPropertyDeclare(strong, Params, NSArray *, parameters);
ArrayPropertyDeclare(strong, Columns, NSArray *, columnsArray);
ArrayPropertyDeclare(strong, Ignore, NSArray *, ignoreArray);


// operation
OperationBlockDeclare(Insert, InsertBlock);
OperationBlockDeclare(Update, UpdateBlock);
OperationBlockDeclare(Delete, DeleteBlock);
OperationBlockDeclare(SaveOrUpdate, SaveOrUpdateBlock);
OperationBlockDeclare(DeleteAll, DeleteAllBlock);
OperationBlockDeclare(Select, SelectBlock);

OperationBlockDeclare(CreateTable, CreateTableBlock);
OperationBlockDeclare(UpdateTable, UpdateTableBlock);
OperationBlockDeclare(DropTable, DropTableBlock);
OperationBlockDeclare(TruncateTable, TruncateTableBlock);

@end
