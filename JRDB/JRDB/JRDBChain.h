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

#define J_Select(_arg_)         ([JRDBChain new].Select([_arg_ class]))
#define J_SelectCount(_arg_)    ([JRDBChain new].CountSelect([_arg_ class]))
#define J_SelectColumns(...)    ([JRDBChain new].ColumnsSelect(_variableListToArray(__VA_ARGS__, 0)))

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
#define OrderJ(_clazz_, _prop_) Order(J(_clazz_, _prop_))
#define GroupJ(_clazz_, _prop_) Group(J(_clazz_, _prop_))

#define J(_clazz_, _prop_)      (((void)(NO && ((void)[_clazz_ new]._prop_, NO)), @"_"#_prop_))

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


typedef JRDBChain *(^BoolBlock)(BOOL value);
typedef JRDBChain *(^ClassBlock)(Class<JRPersistent> clazz);
typedef JRDBChain *(^ObjectBlock)(id value);
typedef JRDBChain *(^ArrayBlock)(NSArray *array);
typedef JRDBChain *(^LimitBlock)(NSUInteger start, NSUInteger length);
typedef JRDBChain *(^CompleteBlock)(JRDBChainComplete complete);



struct JRLimit {
    long long start;
    long long length;
};
typedef struct JRLimit JRLimit;

@interface JRDBChain : NSObject

@property (nonatomic, strong, readonly) id<JRPersistent>          target;///< operation target
@property (nonatomic, strong, readonly) Class<JRPersistent>       targetClazz; ///< operation class
@property (nonatomic, strong, readonly) NSArray<id<JRPersistent>> *targetArray; ///< operation target array


@property (nonatomic, assign, readonly) ChainOperation   operation;///< operation type
@property (nonatomic, strong, readonly) NSString         *tableName;///< operation table name

@property (nonatomic, strong, readonly) NSArray<JRQueryCondition *> *queryCondition; ///< queryConditions whitch generic by where condition
@property (nonatomic, strong, readonly) NSArray<NSString*> *selectColumns;///< customizd select columns array


// value param
@property (nonatomic, copy, readonly  ) ObjectBlock       From;///< sepecific a class for operation

@property (nonatomic, strong, readonly) NSString          *limitString;
@property (nonatomic, assign, readonly) JRLimit           limitIn;
@property (nonatomic, strong, readonly) LimitBlock        Limit;///< limit condition: Limit(start, length)


@property (nonatomic, strong, readonly) FMDatabase        *db;
@property (nonatomic, copy, readonly  ) ObjectBlock       InDB;///< the database : parameter is FMDatabase: InDB(db)


@property (nonatomic, strong, readonly) NSString          *orderBy;
@property (nonatomic, copy, readonly  ) ObjectBlock       Order;///< orderBy condition: parameter is NSString: Order(@"_age")

@property (nonatomic, strong, readonly) NSString          *groupBy;
@property (nonatomic, copy, readonly  ) ObjectBlock       Group;///< groupBy condition: parameter is NSString: Group(@"_age")

@property (nonatomic, strong, readonly) NSString          *whereString;
@property (nonatomic, copy, readonly  ) ObjectBlock       Where;///< where condition: parameter is NSString: Where(@"_age > ? and _name like 'L%'")

@property (nonatomic, strong, readonly) NSString          *whereId;
@property (nonatomic, copy, readonly  ) ObjectBlock       WhereIdIs;///< whereIdIs condition: parameter is NSString: WhereIdIs(@"xxxxxxxxxx")

@property (nonatomic, strong, readonly) id                wherePK;
@property (nonatomic, copy, readonly  ) ObjectBlock       WherePKIs;///< wehrePKIs condition: parameter is id: WherePKIs(obj)

@property (nonatomic, assign, readonly) BOOL              isRecursive;
@property (nonatomic, copy, readonly  ) BoolBlock         Recursive;///< recursive condition, if the operation should recursive, NO by default


@property (nonatomic, assign, readonly) BOOL              isSync;
@property (nonatomic, copy, readonly  ) BoolBlock         Sync;///< sync condition, if the operation should execute on sepecific serial queue and wait on current thread, YES by default

@property (nonatomic, assign, readonly) BOOL              isDesc;
@property (nonatomic, copy, readonly  ) BoolBlock         Desc;///< desc condition, NO by default

@property (nonatomic, assign, readonly) BOOL              useCache;
@property (nonatomic, copy, readonly  ) BoolBlock         Cache;///< cache condition, NO by default

@property (nonatomic, assign, readonly) BOOL              useTransaction;
@property (nonatomic, copy, readonly  ) BoolBlock         Transaction;///< useTransaction , YES by default

@property (nonatomic, copy, readonly  ) JRDBChainComplete completeBlock;
@property (nonatomic, copy, readonly  ) CompleteBlock     Complete;

// array param
@property (nonatomic, strong, readonly) NSArray           *parameters;
@property (nonatomic, copy, readonly  ) ArrayBlock        Params;

@property (nonatomic, strong, readonly) NSArray           *columnsArray;
@property (nonatomic, copy, readonly  ) ArrayBlock        Columns;

@property (nonatomic, strong, readonly) NSArray           *ignoreArray;
@property (nonatomic, copy, readonly  ) ArrayBlock        Ignore;


// operation
@property (nonatomic, copy, readonly  ) ArrayBlock        Insert;///< InsertBlock parameter is NSArray: Insert(@[obj, obj1])
@property (nonatomic, copy, readonly  ) ArrayBlock        Update;///< UpdateBlock parameter is NSArray: Update(@[obj, obj1])
@property (nonatomic, copy, readonly  ) ArrayBlock        Delete;///< DeleteBlock parameter is NSArray: Delete(@[obj, obj1])
@property (nonatomic, copy, readonly  ) ArrayBlock        SaveOrUpdate;///< SaveOrUpdateBlock parameter is NSArray: SaveOrUpdate(@[obj, obj1])

@property (nonatomic, copy, readonly  ) ObjectBlock       InsertOne;///< InsertOneBlock parameter is id<JRPersistent>: InsertOne(obj)
@property (nonatomic, copy, readonly  ) ObjectBlock       UpdateOne;///< UpdateOneBlock parameter is id<JRPersistent>: UpdateOne(obj)
@property (nonatomic, copy, readonly  ) ObjectBlock       DeleteOne;///< DeleteOneBlock parameter is id<JRPersistent>: DeleteOne(obj)
@property (nonatomic, copy, readonly  ) ObjectBlock       SaveOrUpdateOne;///< SaveOrUpdateOneBlock parameter is id<JRPersistent>: SaveOrUpdateOne(obj)

@property (nonatomic, copy, readonly  ) ClassBlock        DeleteAll;///< DeleteAllBlock parameter is Class<JRPersistent>: DeleteAll([Person class])
@property (nonatomic, copy, readonly  ) ArrayBlock        ColumnsSelect;///< SelectBlock parameter is NSArray; <br/> Usage:<br/> (ColumnsSelect(@[@"_name", @"_age"]))
@property (nonatomic, copy, readonly  ) ClassBlock        CountSelect;///< SelectBlock parameter is NSArray; <br/> Usage:<br/>     1-(CountSelect(@[[Person class]]))
@property (nonatomic, copy, readonly  ) ClassBlock        Select;///< SelectBlock parameter is NSArray; <br/> Usage:<br/>     1-(Select(@[[Person class]]))

@property (nonatomic, copy, readonly  ) ClassBlock        CreateTable;///< CreateTableBlock parameter is Class<JRPersistent>: CreateTable([Person class])
@property (nonatomic, copy, readonly  ) ClassBlock        UpdateTable;///< UpdateTableBlock parameter is Class<JRPersistent>: UpdateTable([Person class])
@property (nonatomic, copy, readonly  ) ClassBlock        DropTable;///< DropTableBlock parameter is Class<JRPersistent>: DropTable([Person class])
@property (nonatomic, copy, readonly  ) ClassBlock        TruncateTable;///< TruncateTableBlock parameter is Class<JRPersistent>: TruncateTable([Person class])


/**
 *  the method that execute the operation
 *
 *  @param complete
 */
- (id)exe:(JRDBChainComplete)complete;

- (BOOL)isQuerySingle;

@end
