//
//  JRDBChain.h
//  JRDB
//
//  Created by JMacMini on 16/7/11.
//  Copyright © 2016年 Jrwong. All rights reserved.
//  链式调用的关键类

#import <Foundation/Foundation.h>
#import "JRPersistent.h"

#pragma mark - convenience marco

#define jr_weak(object) __weak __typeof__(object) weak##_##object = object
#define jr_strong(object) __typeof__(object) object = weak##_##object

#define J_Select(...)           ([JRDBChain new].Select((_variableListToArray(__VA_ARGS__, 0))))
#define J_SelectJ(_arg_)        (J_Select([_arg_ class]))

#define J_Insert(...)           ([JRDBChain new].Insert(_variableListToArray(__VA_ARGS__, 0)))
#define J_Update(...)           ([JRDBChain new].Update(_variableListToArray(__VA_ARGS__, 0)))
#define J_Delete(...)           ([JRDBChain new].Delete(_variableListToArray(__VA_ARGS__, 0)))
#define J_SaveOrUpdate(...)     ([JRDBChain new].SaveOrUpdate(_variableListToArray(__VA_ARGS__, 0)))

#define J_DeleteAll(_arg_)      ([JRDBChain new].DeleteAll([_arg_ class]))

#define J_CreateTable(_arg_)    ([JRDBChain new].CreateTable([_arg_ class]))
#define J_UpdateTable(_arg_)    ([JRDBChain new].UpdateTable([_arg_ class]))
#define J_DropTable(_arg_)      ([JRDBChain new].DropTable([_arg_ class]))
#define J_TruncateTable(_arg_)  ([JRDBChain new].TruncateTable([_arg_ class]))

#define ParamsJ(...)            Params((_variableListToArray(__VA_ARGS__, 0)))
#define ColumnsJ(...)           Columns((_variableListToArray(__VA_ARGS__, 0)))
#define IgnoreJ(...)            Ignore((_variableListToArray(__VA_ARGS__, 0)))

#define FromJ(_arg_)            From([_arg_ class])
#define WhereJ(_arg_)           Where(@#_arg_)
#define OrderJ(_arg_)           Order(@#_arg_)
#define GroupJ(_arg_)           Group(@#_arg_)

static inline NSArray * _variableListToArray(id first, ...) {
    NSMutableArray *args = [NSMutableArray array];
    if (!first) {
        return args;
    }
    [args addObject:first];
    va_list valist;
    va_start(valist, first);
    id arg;
    while( (arg = va_arg(valist,id)) )
    {
        if ( arg ){
            [args addObject:arg];
        }
    }
    va_end(valist);
    return [args copy];
}

static inline NSArray * _JRToArray(id arg) {
    if (!arg) NSLog(@"warning: _JRBoxValue should not pass a nil value");
    return [arg isKindOfClass:[NSArray class]] ? arg : arg ? @[arg] : @[];
}


typedef enum {
    CInsert = 1,
    CUpdate,
    CDelete,
    CSaveOrUpdate,
    CDeleteAll,
    CSelect,
    CSelectSingle,
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

typedef JRDBChain *(^InsertOneBlock)(id<JRPersistent> one);
typedef JRDBChain *(^UpdateOneBlock)(id<JRPersistent> one);
typedef JRDBChain *(^DeleteOneBlock)(id<JRPersistent> one);
typedef JRDBChain *(^SaveOrUpdateOneBlock)(id<JRPersistent> one);

typedef JRDBChain *(^SelectBlock)(NSArray *array);


typedef JRDBChain *(^DeleteAllBlock)(Class<JRPersistent> clazz);

typedef JRDBChain *(^CreateTableBlock)(Class<JRPersistent> clazz);
typedef JRDBChain *(^UpdateTableBlock)(Class<JRPersistent> clazz);
typedef JRDBChain *(^DropTableBlock)(Class<JRPersistent> clazz);
typedef JRDBChain *(^TruncateTableBlock)(Class<JRPersistent> clazz);


#define BlockPropertyDeclare(_ownership_, _name_, _paramType_, _paramName_) \
@property(nonatomic,_ownership_,readonly)_paramType_ _paramName_;\
@property(nonatomic,copy,readonly)JRDBChain*(^_name_)(_paramType_ param);


#define OperationBlockDeclare(_name_, _type_) \
@property(nonatomic,copy,readonly)_type_ _name_;

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


// value param
@property (nonatomic, copy) JRDBChain *(^From)(id from);///< 接收Class类

@property (nonatomic, strong, readonly) JRDBChain *(^Limit)(NSUInteger start, NSUInteger length);
@property (nonatomic, assign, readonly) JRLimit limitIn;
@property (nonatomic, strong, readonly) NSString *limitString;


BlockPropertyDeclare(strong, InDB, FMDatabase *, db);
BlockPropertyDeclare(strong, Order, NSString *, orderBy);
BlockPropertyDeclare(strong, Group, NSString *, groupBy);
BlockPropertyDeclare(strong, Where, NSString *, whereString);
BlockPropertyDeclare(strong, WhereIdIs, NSString *, whereId);
BlockPropertyDeclare(strong, WherePKIs, id, wherePK);
BlockPropertyDeclare(assign, Recursive, BOOL, isRecursive);
BlockPropertyDeclare(assign, Sync, BOOL, isSync);
BlockPropertyDeclare(assign, Desc, BOOL, isDesc);
BlockPropertyDeclare(assign, Cache, BOOL, useCache);
BlockPropertyDeclare(assign, Trasaction, BOOL, useTransaction);
BlockPropertyDeclare(copy, Complete, JRDBChainComplete, completeBlock);

// array param
BlockPropertyDeclare(strong, Params, NSArray *, parameters);
BlockPropertyDeclare(strong, Columns, NSArray *, columnsArray);
BlockPropertyDeclare(strong, Ignore, NSArray *, ignoreArray);


// operation
OperationBlockDeclare(Insert, InsertBlock);
OperationBlockDeclare(Update, UpdateBlock);
OperationBlockDeclare(Delete, DeleteBlock);
OperationBlockDeclare(SaveOrUpdate, SaveOrUpdateBlock);

OperationBlockDeclare(InsertOne, InsertOneBlock);
OperationBlockDeclare(UpdateOne, UpdateOneBlock);
OperationBlockDeclare(DeleteOne, DeleteOneBlock);
OperationBlockDeclare(SaveOrUpdateOne, SaveOrUpdateOneBlock);

OperationBlockDeclare(DeleteAll, DeleteAllBlock);
OperationBlockDeclare(Select, SelectBlock);

OperationBlockDeclare(CreateTable, CreateTableBlock);
OperationBlockDeclare(UpdateTable, UpdateTableBlock);
OperationBlockDeclare(DropTable, DropTableBlock);
OperationBlockDeclare(TruncateTable, TruncateTableBlock);

- (BOOL)isQuerySingle;
- (id)exe:(JRDBChainComplete)complete;

@end
