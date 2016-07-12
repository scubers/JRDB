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
 
 c.Insert(p).Table(name).InDB(db).Recursive(YES).NowInMain(NO).Complete(^(BOOL success){})
 
 c.Update(p).Table(name).InDB(db).Recursive(YES).NowInMain(NO).Columns().Ignore().Complete(^(BOOL success){})
 
 c.Delete(p).Table(name).InDB(db).Recursive(YES).NowInMain(NO).Complete(^(BOOL success){})
 
 c.DeleteAll(p.class).From(name).InDB(db).Recursive(YES).NowInMain(NO).Complete(^(BOOL success){})
 
 c.Select(p.class).From(name).InDB(db).Recursive(YES).Where(@"_age = ?").Params().Group().Order().limit().Desc(YES)
 
 
 */

#define jr_weak(object) __weak __typeof__(object) weak##_##object = object
#define jr_strong(object) __typeof__(object) object = weak##_##object

typedef enum {
    CInsert = 1,
    CUpdate,
    CDelete,
    CDeleteAll,
    CSelect,
    
} ChainOperation;

@class FMDatabase, JRDBChain;

typedef void(^JRDBChainComplete)(JRDBChain *chain, id result);

typedef JRDBChain *(^InsertBlock)(id<JRPersistent> obj);
typedef JRDBChain *(^UpdateBlock)(id<JRPersistent> obj);
typedef JRDBChain *(^DeleteBlock)(id<JRPersistent> obj);

typedef JRDBChain *(^DeleteAllBlock)(Class<JRPersistent> clazz);
typedef JRDBChain *(^SelectBlock)(Class<JRPersistent> clazz);

#define BlockPropertyDeclare(_ownership_, _name_, _paramType_, _paramName_) \
@property(nonatomic,_ownership_,readonly)_paramType_ _paramName_;\
@property(nonatomic,copy,readonly)JRDBChain*(^_name_)(_paramType_ param);

#define OperationBlockDeclear(_name_, _type_) \
@property(nonatomic,copy,readonly)_type_ _name_;


@interface JRDBChain : NSObject

@property (nonatomic, strong, readonly) id target; ///< 有可能是obj对象，也有可能是class对象
@property (nonatomic, assign, readonly) ChainOperation operation;

BlockPropertyDeclare(strong, InDB, FMDatabase *, db);
BlockPropertyDeclare(strong, From, NSString *, tableName);

BlockPropertyDeclare(strong, Order, NSString *, orderBy);
BlockPropertyDeclare(strong, Group, NSString *, groupBy);
BlockPropertyDeclare(strong, Limit, NSString *, limitIn);

BlockPropertyDeclare(strong, Where, NSString *, whereString);
BlockPropertyDeclare(strong, Params, NSArray *, parameters);

BlockPropertyDeclare(strong, Columns, NSArray *, columnsArray);
BlockPropertyDeclare(strong, Ignore, NSArray *, ignoreArray);

BlockPropertyDeclare(assign, Recursive, BOOL, isRecursive);
BlockPropertyDeclare(assign, NowInMain, BOOL, isNowInMain);
BlockPropertyDeclare(assign, Trasaction, BOOL, useTransaction);
BlockPropertyDeclare(assign, Desc, BOOL, isDesc);
BlockPropertyDeclare(copy, Complete, JRDBChainComplete, completeBlock);

// block
OperationBlockDeclear(Insert, InsertBlock);
OperationBlockDeclear(Update, UpdateBlock);
OperationBlockDeclear(Delete, DeleteBlock);
OperationBlockDeclear(DeleteAll, DeleteAllBlock);
OperationBlockDeclear(Select, SelectBlock);

@end
