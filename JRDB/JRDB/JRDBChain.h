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

#define J(_prop_)               (((void)(NO && ((void)[((id)[NSObject new]) _prop_], NO)), @"_"#_prop_))

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

@class FMDatabase, JRDBChain, JRQueryCondition;


typedef JRDBChain * _Nonnull (^JRObjectBlock)(id _Nonnull value);
typedef JRDBChain * _Nonnull (^JRBoolBlock)(BOOL flag);
//typedef JRDBChain * _Nonnull (^JRIntegerBlock)(NSInteger value);
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
//typedef struct JRLimit JRLimit;

@interface JRDBChain<T:id<JRPersistent>> : NSObject

@property (nonatomic, strong, readonly, nullable) JRDBChain<T> * subChain;///< has sub query

@property (nonatomic, strong, readonly, nullable) T target;///< operation target
@property (nonatomic, strong, readonly, nullable) Class<JRPersistent>       targetClazz; ///< operation class
@property (nonatomic, strong, readonly, nullable) NSArray<T> *targetArray; ///< operation target array


@property (nonatomic, assign, readonly) ChainOperation   operation;///< operation type
@property (nonatomic, strong, readonly, nullable) NSString         *tableName;///< operation table name

@property (nonatomic, strong, readonly, nullable) NSArray<JRQueryCondition *> *queryCondition; ///< queryConditions which generic by where condition
@property (nonatomic, strong, readonly, nullable) JRSql *querySql; ///< jrSql which generic by Self when execute query
@property (nonatomic, strong, readonly, nullable) NSArray<NSString*> *selectColumns;///< customizd select columns array


// value param
@property (nonatomic, copy, readonly, nonnull   ) JRObjectBlockDefine(T, From);///< sepecific a class for operation

@property (nonatomic, strong, readonly, nullable) NSString          *limitString;
@property (nonatomic, assign, readonly          ) JRLimit           limitIn;
@property (nonatomic, strong, readonly, nonnull ) JRLimitBlock      Limit;///< limit condition: Limit(start, length)


@property (nonatomic, strong, readonly, nonnull ) FMDatabase        *db;
@property (nonatomic, copy, readonly, nonnull   ) JRObjectBlockDefine(T, InDB);///< the database : parameter is FMDatabase: InDB(db)


@property (nonatomic, strong, readonly, nullable) NSString          *orderBy;
@property (nonatomic, copy, readonly, nonnull   ) JRObjectBlockDefine(T, Order);///< orderBy condition: parameter is NSString: Order(@"_age")

@property (nonatomic, strong, readonly, nullable) NSString          *groupBy;
@property (nonatomic, copy, readonly, nonnull   ) JRObjectBlockDefine(T, Group);///< groupBy condition: parameter is NSString: Group(@"_age")

@property (nonatomic, strong, readonly, nullable) NSString          *whereString;
@property (nonatomic, copy, readonly, nonnull   ) JRObjectBlockDefine(T, Where);///< where condition: parameter is NSString: Where(@"_age > ? and _name like 'L%'")

@property (nonatomic, strong, readonly, nullable) NSString          *whereId;
@property (nonatomic, copy, readonly, nonnull   ) JRObjectBlockDefine(T, WhereIdIs);///< whereIdIs condition: parameter is NSString: WhereIdIs(@"xxxxxxxxxx")

@property (nonatomic, strong, readonly, nullable) id                wherePK;
@property (nonatomic, copy, readonly, nonnull   ) JRObjectBlockDefine(T, WherePKIs);///< wehrePKIs condition: parameter is id: WherePKIs(obj)

@property (nonatomic, assign, readonly          ) BOOL              isRecursive;
@property (nonatomic, copy, readonly, nonnull   ) JRBoolBlockDefine(T, Recursive);///< recursive condition, if the operation should recursive, NO by default
- (instancetype _Nonnull)Recursively;///< equal to Recursive(YES)
- (instancetype _Nonnull)UnRecursively;///< equal to Recursive(NO)

@property (nonatomic, assign, readonly          ) BOOL              isSync;
@property (nonatomic, copy, readonly, nonnull   ) JRBoolBlockDefine(T, Sync);///< sync condition, if the operation should execute on sepecific serial queue and wait on current thread, YES by default
- (instancetype _Nonnull)UnSafely;///< equal to Sync(NO)
- (instancetype _Nonnull)Safely;///< equal to Sync(YES)


@property (nonatomic, assign, readonly          ) BOOL              isDesc;
@property (nonatomic, copy, readonly, nonnull   ) JRBoolBlockDefine(T, Desc);///< desc condition, NO by default
- (instancetype _Nonnull)Descend;///< equal to Desc(YES)
- (instancetype _Nonnull)Ascend;///< equal to Desc(NO)

@property (nonatomic, assign, readonly          ) BOOL              useCache;
@property (nonatomic, copy, readonly, nonnull   ) JRBoolBlockDefine(T, Cache);///< cache condition, NO by default
- (instancetype _Nonnull)Cached;///< equal to Cache(YES)
- (instancetype _Nonnull)NoCached;///< equal to Cache(NO)

@property (nonatomic, assign, readonly          ) BOOL              useTransaction;
@property (nonatomic, copy, readonly, nonnull   ) JRBoolBlockDefine(T, Transaction);///< useTransaction , YES by default
- (instancetype _Nonnull)NoTransaction;///< equal to Transaction(NO)
- (instancetype _Nonnull)Transactional;///< equal to Transaction(YES)

@property (nonatomic, copy, readonly, nullable  ) JRDBChainComplete completeBlock;
@property (nonatomic, copy, readonly, nonnull   ) JRCompleteBlockDefine(T, Complete);

// array param
@property (nonatomic, strong, readonly, nullable) NSArray           *parameters;
@property (nonatomic, copy, readonly, nonnull   ) JRArrayBlockDefine(T, Params);

@property (nonatomic, strong, readonly, nullable) NSArray           *columnsArray;
@property (nonatomic, copy, readonly, nonnull   ) JRArrayBlockDefine(T, Columns);

@property (nonatomic, strong, readonly, nullable) NSArray           *ignoreArray;
@property (nonatomic, copy, readonly, nonnull   ) JRArrayBlockDefine(T, Ignore);


// operation
@property (nonatomic, copy, readonly, nonnull   ) JRArrayBlockDefine(T, Insert);///< InsertBlock parameter is NSArray: Insert(@[obj, obj1])
@property (nonatomic, copy, readonly, nonnull   ) JRArrayBlockDefine(T, Update);///< UpdateBlock parameter is NSArray: Update(@[obj, obj1])
@property (nonatomic, copy, readonly, nonnull   ) JRArrayBlockDefine(T, Delete);///< DeleteBlock parameter is NSArray: Delete(@[obj, obj1])
@property (nonatomic, copy, readonly, nonnull   ) JRArrayBlockDefine(T, SaveOrUpdate);///< SaveOrUpdateBlock parameter is NSArray: SaveOrUpdate(@[obj, obj1])

@property (nonatomic, copy, readonly, nonnull   ) JRObjectBlockDefine(T, InsertOne);///< InsertOneBlock parameter is id<JRPersistent>: InsertOne(obj)
@property (nonatomic, copy, readonly, nonnull   ) JRObjectBlockDefine(T, UpdateOne);///< UpdateOneBlock parameter is id<JRPersistent>: UpdateOne(obj)
@property (nonatomic, copy, readonly, nonnull   ) JRObjectBlockDefine(T, DeleteOne);///< DeleteOneBlock parameter is id<JRPersistent>: DeleteOne(obj)
@property (nonatomic, copy, readonly, nonnull   ) JRObjectBlockDefine(T, SaveOrUpdateOne);///< SaveOrUpdateOneBlock parameter is id<JRPersistent>: SaveOrUpdateOne(obj)

@property (nonatomic, copy, readonly, nonnull   ) JRClassBlockDefine(T, DeleteAll);///< DeleteAllBlock parameter is Class<JRPersistent>: DeleteAll([Person class])
@property (nonatomic, copy, readonly, nonnull   ) JRArrayBlockDefine(T, ColumnsSelect);///< SelectBlock parameter is NSArray; <br/> Usage:<br/> (ColumnsSelect(@[@"_name", @"_age"]))
@property (nonatomic, copy, readonly, nonnull   ) JRClassBlockDefine(T, CountSelect);///< SelectBlock parameter is NSArray; <br/> Usage:<br/>     1-(CountSelect(@[[Person class]]))
@property (nonatomic, copy, readonly, nonnull   ) JRClassBlockDefine(T, Select);///< SelectBlock parameter is NSArray; <br/> Usage:<br/>     1-(Select(@[[Person class]]))

@property (nonatomic, copy, readonly, nonnull   ) JRClassBlockDefine(T, CreateTable);///< CreateTableBlock parameter is Class<JRPersistent>: CreateTable([Person class])
@property (nonatomic, copy, readonly, nonnull   ) JRClassBlockDefine(T, UpdateTable);///< UpdateTableBlock parameter is Class<JRPersistent>: UpdateTable([Person class])
@property (nonatomic, copy, readonly, nonnull   ) JRClassBlockDefine(T, DropTable);///< DropTableBlock parameter is Class<JRPersistent>: DropTable([Person class])
@property (nonatomic, copy, readonly, nonnull   ) JRClassBlockDefine(T, TruncateTable);///< TruncateTableBlock parameter is Class<JRPersistent>: TruncateTable([Person class])


/**
 *  the method that execute the operation
 *
 *  @param complete
 */
- (JRDBResult * _Nonnull)exe:(JRDBChainComplete _Nullable)complete;
- (JRDBResult * _Nonnull)exe;

- (BOOL)updateResult;
- (NSUInteger)count;
- (T _Nullable)object;
- (NSArray<T> * _Nonnull)list;

#pragma mark - macro method will not execute
- (JRObjectBlock _Nonnull)FromJ NS_SWIFT_UNAVAILABLE("macro method");///< will not execute cause the macro
- (JRArrayBlock _Nonnull)ParamsJ NS_SWIFT_UNAVAILABLE("macro method");///< will not execute cause the macro
- (JRArrayBlock _Nonnull)ColumnsJ NS_SWIFT_UNAVAILABLE("macro method");///< will not execute cause the macro
- (JRArrayBlock _Nonnull)IgnoreJ NS_SWIFT_UNAVAILABLE("macro method");///< will not execute cause the macro
- (JRObjectBlock _Nonnull)WhereJ NS_SWIFT_UNAVAILABLE("macro method");///< will not execute cause the macro
- (JRObjectBlock _Nonnull)OrderJ NS_SWIFT_UNAVAILABLE("macro method");///< will not execute cause the macro
- (JRObjectBlock _Nonnull)GroupJ NS_SWIFT_UNAVAILABLE("macro method");///< will not execute cause the macro

@end
