//
//  JRDBChain.h
//  JRDB
//
//  Created by JMacMini on 16/7/11.
//  Copyright © 2016年 Jrwong. All rights reserved.
//  链式调用的关键类

#import <Foundation/Foundation.h>
#import "JRPersistent.h"
#import "JRDBResult.h"
#import "JRSqlGenerator.h"
#import "JRPersistentHandler.h"
#import "JRDBChainCondition.h"

@class JRDBChain;

#pragma mark - convenience marco

#define J_Select(_arg_)         ([JRDBChain<_arg_ *> new].Select([_arg_ class]))
#define J_SelectCount(_arg_)    ([JRDBChain new].CountSelect([_arg_ class]))
#define J_SelectColumns(...)    ([JRDBChain new].ColumnsSelect(_variableListToArray(__VA_ARGS__, 0)))

#define J_Insert(...)           ([JRDBChain new].Insert(_variableListToArray(__VA_ARGS__, 0)))
#define J_Update(...)           ([JRDBChain new].Update(_variableListToArray(__VA_ARGS__, 0)))
#define J_Delete(...)           ([JRDBChain new].Delete(_variableListToArray(__VA_ARGS__, 0)))
#define J_SaveOrUpdate(...)     ([JRDBChain new].SaveOrUpdate(_variableListToArray(__VA_ARGS__, 0)))

#define J_DeleteAll(_arg_)      ([JRDBChain new].DeleteAll([_arg_ class]))

#define J_CreateTable(_arg_)    ([JRDBChain new].CreateTable([_arg_ class])).updateResult
#define J_UpdateTable(_arg_)    ([JRDBChain new].UpdateTable([_arg_ class])).updateResult
#define J_DropTable(_arg_)      ([JRDBChain new].DropTable([_arg_ class])).updateResult
#define J_TruncateTable(_arg_)  ([JRDBChain new].TruncateTable([_arg_ class])).updateResult

#define ParamsJ(...)            Params((_variableListToArray(__VA_ARGS__, 0)))
#define ColumnsJ(...)           Columns((_variableListToArray(__VA_ARGS__, 0)))
#define IgnoreJ(...)            Ignore((_variableListToArray(__VA_ARGS__, 0)))

#define FromJ(_arg_)            From([_arg_ class])
#define WhereJ(_arg_)           Where(@#_arg_)
#define OrderJ(_prop_)          Order(J(_prop_))
#define GroupJ(_prop_)          Group(J(_prop_))
#define AndJ(_prop_)            And(J(_prop_))
#define OrJ(_prop_)             Or(J(_prop_))

NS_ASSUME_NONNULL_BEGIN

static inline NSArray * _Nonnull _variableListToArray(id _Nullable first, ...) {
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
    return [args copy];
}


typedef NS_ENUM(NSInteger, ChainOperation) {
    COperationNone = 0,
    CInsert,
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

};

@class JRDBChain;


typedef JRDBChain * _Nonnull (^JRObjectBlock)(id _Nonnull value);
typedef JRDBChain * _Nonnull (^JRBoolBlock)(BOOL flag);
typedef JRDBChain * _Nonnull (^JRClassBlock)(Class<JRPersistent> _Nonnull clazz);
typedef JRDBChain * _Nonnull (^JRArrayBlock)(NSArray * _Nonnull array);
typedef JRDBChain * _Nonnull (^JRLimitBlock)(NSUInteger start, NSUInteger length);
typedef JRDBChain * _Nonnull (^JRCompleteBlock)(JRDBChainComplete _Nonnull complete);

#define JRObjectBlockDefine(_generictype_, _name_)\
JRDBChain<_generictype_> * _Nonnull(^_name_)(id _Nonnull obj)

#define JRBoolBlockDefine(_generictype_, _name_) \
JRDBChain<_generictype_> * _Nonnull(^_name_)(BOOL value)

#define JRClassBlockDefine(_generictype_, _name_)\
JRDBChain<_generictype_> * _Nonnull(^_name_)(Class<JRPersistent> _Nonnull clazz)

#define JRArrayBlockDefine(_generictype_, _name_)\
JRDBChain<_generictype_> * _Nonnull(^_name_)(NSArray * _Nonnull array)

#define JRLimitBlockDefine(_generictype_, _name_)\
JRDBChain<_generictype_> * _Nonnull(^_name_)(NSUInteger start, NSUInteger length)

#define JRCompleteBlockDefine(_generictype_, _name_)\
JRDBChain<_generictype_> * _Nonnull(^_name_)(JRDBChainComplete _Nonnull complete)

typedef struct {
    long long start;
    long long length;
} JRLimit;

@interface JRDBChain<T:id<JRPersistent>> : NSObject

@property (nonatomic, strong, readonly, nullable) JRDBChain<T> * subChain;///< has sub query

@property (nonatomic, strong, readonly, nullable) T target;///< operation target
@property (nonatomic, strong, readonly, nullable) Class<JRPersistent>       targetClazz; ///< operation class
@property (nonatomic, strong, readonly, nullable) NSArray<T> *targetArray; ///< operation target array


@property (nonatomic, assign, readonly) ChainOperation   operation;///< operation type
@property (nonatomic, strong, readonly, nullable) NSString         *tableName;///< operation table name

@property (nonatomic, strong, readonly, nullable) JRSql *querySql; ///< jrSql which generic by Self when execute query
@property (nonatomic, strong, readonly, nullable) NSArray<NSString*> *selectColumns;///< customizd select columns array


// value param
@property (nonatomic, copy, readonly) JRObjectBlockDefine(T, From);///< sepecific a class for operation

@property (nonatomic, strong, readonly, nullable) NSString*limitString;
@property (nonatomic, assign, readonly) JRLimit limitIn;
@property (nonatomic, strong, readonly) JRLimitBlock      Limit;///< limit condition: Limit(start, length)


@property (nonatomic, strong, readonly) id<JRPersistentHandler> db;
@property (nonatomic, copy, readonly  ) JRObjectBlockDefine(T, InDB);///< the database : parameter is id<JRPersistentBaseHandler>: InDB(db)


@property (nonatomic, strong, readonly, nullable) NSString*orderBy;
@property (nonatomic, copy, readonly) JRObjectBlockDefine(T, Order);///< orderBy condition: parameter is NSString: Order(@"_age")

@property (nonatomic, strong, readonly, nullable) NSString*groupBy;
@property (nonatomic, copy, readonly) JRObjectBlockDefine(T, Group);///< groupBy condition: parameter is NSString: Group(@"_age")

@property (nonatomic, strong, readonly, nullable) NSString*whereString;
@property (nonatomic, copy, readonly) JRObjectBlockDefine(T, Where);///< where condition: parameter is NSString: Where(@"_age > ? and _name like 'L%'")

@property (nonatomic, strong, readonly, nullable) NSString*whereId;
@property (nonatomic, copy, readonly) JRObjectBlockDefine(T, WhereIdIs);///< whereIdIs condition: parameter is NSString: WhereIdIs(@"xxxxxxxxxx")

@property (nonatomic, strong, readonly, nullable) id      wherePK;
@property (nonatomic, copy, readonly) JRObjectBlockDefine(T, WherePKIs);///< wehrePKIs condition: parameter is id: WherePKIs(obj)

@property (nonatomic, assign, readonly) BOOL    isRecursive;
@property (nonatomic, copy, readonly) JRBoolBlockDefine(T, Recursive);///< recursive condition, if the operation should recursive, NO by default
- (instancetype)Recursively;///< equal to Recursive(YES)
- (instancetype)UnRecursively;///< equal to Recursive(NO)

@property (nonatomic, assign, readonly) BOOL    isSync;
@property (nonatomic, copy, readonly) JRBoolBlockDefine(T, Sync);///< sync condition, if the operation should execute on sepecific serial queue and wait on current thread, YES by default
- (instancetype)UnSafely;///< equal to Sync(NO)
- (instancetype)Safely;///< equal to Sync(YES)


@property (nonatomic, assign, readonly) BOOL    isDesc;
@property (nonatomic, copy, readonly) JRBoolBlockDefine(T, Desc);///< desc condition, NO by default
- (instancetype)Descend;///< equal to Desc(YES)
- (instancetype)Ascend;///< equal to Desc(NO)

@property (nonatomic, assign, readonly) BOOL    useTransaction;
@property (nonatomic, copy, readonly) JRBoolBlockDefine(T, Transaction);///< useTransaction , YES by default
- (instancetype)NoTransaction;///< equal to Transaction(NO)
- (instancetype)Transactional;///< equal to Transaction(YES)

// array param
@property (nonatomic, strong, readonly, nullable) NSArray *parameters;
@property (nonatomic, copy, readonly) JRArrayBlockDefine(T, Params);

@property (nonatomic, strong, readonly, nullable) NSArray *columnsArray;
@property (nonatomic, copy, readonly) JRArrayBlockDefine(T, Columns);

@property (nonatomic, strong, readonly, nullable) NSArray *ignoreArray;
@property (nonatomic, copy, readonly) JRArrayBlockDefine(T, Ignore);


// operation
@property (nonatomic, copy, readonly) JRArrayBlockDefine(T, Insert);///< InsertBlock parameter is NSArray: Insert(@[obj, obj1])
@property (nonatomic, copy, readonly) JRArrayBlockDefine(T, Update);///< UpdateBlock parameter is NSArray: Update(@[obj, obj1])
@property (nonatomic, copy, readonly) JRArrayBlockDefine(T, Delete);///< DeleteBlock parameter is NSArray: Delete(@[obj, obj1])
@property (nonatomic, copy, readonly) JRArrayBlockDefine(T, SaveOrUpdate);///< SaveOrUpdateBlock parameter is NSArray: SaveOrUpdate(@[obj, obj1])

@property (nonatomic, copy, readonly) JRObjectBlockDefine(T, InsertOne);///< InsertOneBlock parameter is id<JRPersistent>: InsertOne(obj)
@property (nonatomic, copy, readonly) JRObjectBlockDefine(T, UpdateOne);///< UpdateOneBlock parameter is id<JRPersistent>: UpdateOne(obj)
@property (nonatomic, copy, readonly) JRObjectBlockDefine(T, DeleteOne);///< DeleteOneBlock parameter is id<JRPersistent>: DeleteOne(obj)
@property (nonatomic, copy, readonly) JRObjectBlockDefine(T, SaveOrUpdateOne);///< SaveOrUpdateOneBlock parameter is id<JRPersistent>: SaveOrUpdateOne(obj)

@property (nonatomic, copy, readonly) JRClassBlockDefine(T, DeleteAll);///< DeleteAllBlock parameter is Class<JRPersistent>: DeleteAll([Person class])
@property (nonatomic, copy, readonly) JRArrayBlockDefine(T, ColumnsSelect);///< SelectBlock parameter is NSArray; <br/> Usage:<br/> (ColumnsSelect(@[@"_name", @"_age"]))
@property (nonatomic, copy, readonly) JRClassBlockDefine(T, CountSelect);///< SelectBlock parameter is NSArray; <br/> Usage:<br/>     1-(CountSelect(@[[Person class]]))
@property (nonatomic, copy, readonly) JRClassBlockDefine(T, Select);///< SelectBlock parameter is NSArray; <br/> Usage:<br/>     1-(Select(@[[Person class]]))

@property (nonatomic, copy, readonly) JRClassBlockDefine(T, CreateTable);///< CreateTableBlock parameter is Class<JRPersistent>: CreateTable([Person class])
@property (nonatomic, copy, readonly) JRClassBlockDefine(T, UpdateTable);///< UpdateTableBlock parameter is Class<JRPersistent>: UpdateTable([Person class])
@property (nonatomic, copy, readonly) JRClassBlockDefine(T, DropTable);///< DropTableBlock parameter is Class<JRPersistent>: DropTable([Person class])
@property (nonatomic, copy, readonly) JRClassBlockDefine(T, TruncateTable);///< TruncateTableBlock parameter is Class<JRPersistent>: TruncateTable([Person class])

#pragma mark conditions

@property (nonatomic, strong) NSMutableArray<JRDBChainCondition *> *conditions;

- (JRDBChainCondition *(^)(NSString *propName))And;
- (JRDBChainCondition *(^)(id param))Or;

/**
 the method that execute the operation
 */
- (JRDBResult *)exe;

- (BOOL)updateResult;
- (NSUInteger)count;
- (T _Nullable)object;
- (NSArray<T> *)list;

#pragma mark - macro method will not execute

- (JRObjectBlock)FromJ NS_SWIFT_UNAVAILABLE("macro method");///< will not execute cause the macro
- (JRArrayBlock)ParamsJ NS_SWIFT_UNAVAILABLE("macro method");///< will not execute cause the macro
- (JRArrayBlock)ColumnsJ NS_SWIFT_UNAVAILABLE("macro method");///< will not execute cause the macro
- (JRArrayBlock)IgnoreJ NS_SWIFT_UNAVAILABLE("macro method");///< will not execute cause the macro
- (JRObjectBlock)WhereJ NS_SWIFT_UNAVAILABLE("macro method");///< will not execute cause the macro
- (JRObjectBlock)OrderJ NS_SWIFT_UNAVAILABLE("macro method");///< will not execute cause the macro
- (JRObjectBlock)GroupJ NS_SWIFT_UNAVAILABLE("macro method");///< will not execute cause the macro
- (JRDBChainCondition *(^)(NSString *propName))AndJ NS_SWIFT_UNAVAILABLE("macro method");///< will not execute cause the macro
- (JRDBChainCondition *(^)(id param))OrJ NS_SWIFT_UNAVAILABLE("macro method");///< will not execute cause the macro
@end



@interface JRDBChain (Recursive)

- (id _Nullable)jr_executeQueryChainRecusively;
- (BOOL)jr_executeUpdateChainRecusively;

@end

NS_ASSUME_NONNULL_END
