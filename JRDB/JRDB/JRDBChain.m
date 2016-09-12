//
//  JRDBChain.m
//  JRDB
//
//  Created by JMacMini on 16/7/11.
//  Copyright © 2016年 Jrwong. All rights reserved.
//

#import "JRDBChain.h"
#import "FMDatabase+JRDB.h"
#import "FMDatabase+Chain.h"
#import "JRDBMgr.h"
#import <objc/runtime.h>
#import "NSObject+Reflect.h"
#import "JRQueryCondition.h"
#import "JRSqlGenerator.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Woverriding-method-mismatch"
#pragma clang diagnostic ignored "-Wmismatched-return-types"


@interface JRDBChain ()
{
    JRSql *_subSql;
}

@end

@implementation JRDBChain

@synthesize target         = _target;
@synthesize targetArray    = _targetArray;
@synthesize targetClazz    = _targetClazz;
@synthesize operation      = _operation;
@synthesize queryCondition = _queryCondition;
@synthesize selectColumns  = _selectColumns;
@synthesize limitIn        = _limitIn;
@synthesize limitString    = _limitString;
@synthesize db             = _db;
@synthesize groupBy        = _groupBy;
@synthesize orderBy        = _orderBy;
@synthesize whereString    = _whereString;
@synthesize isRecursive    = _isRecursive;
@synthesize isSync         = _isSync;
@synthesize useTransaction = _useTransaction;
@synthesize useCache       = _useCache;
@synthesize isDesc         = _isDesc;
@synthesize completeBlock  = _completeBlock;
@synthesize parameters     = _parameters;
@synthesize columnsArray   = _columnsArray;
@synthesize ignoreArray    = _ignoreArray;
@synthesize tableName      = _tableName;

- (instancetype)init {
    if (self = [super init]) {
        _isRecursive    = NO;
        _useCache       = NO;
        _useTransaction = YES;
        _isSync         = YES;
        _db             = [JRDBMgr defaultDB];
        _limitIn        = (JRLimit){-1, -1};
    }
    return self;
}

- (JRDBResult *)exe:(JRDBChainComplete)complete {

    if (!self.target && !self.targetArray.count && !self.targetClazz) {
        NSLog(@"chain excute error, target or targetArray or targetClazz is nil");
        return nil;
    }
    
    if ([self isQuerySingle]) {
        _operation = CSelectSingle;
    }
    
    if (complete) {
        _completeBlock = complete;
    }

    id result;
    switch (_operation) {
        case CSelect:
        case CSelectSingle:
            result = [_db jr_executeQueryChain:self];break;
            
        case CSelectCustomized:
        case CSelectCount:
            result = [_db jr_executeCustomizedQueryChain:self];break;
            
        default:
            result = @([_db jr_executeUpdateChain:self]);
    }
    
    JRDBResult *finalResult;
    switch (self.operation) {
        case CCreateTable:
        case CUpdateTable:
        case CDropTable:
        case CTruncateTable:
        case CInsert:
        case CUpdate:
        case CDeleteAll:
        case CDelete:
        case CSaveOrUpdate:
            finalResult = [JRDBResult resultWithBool:[result boolValue]];break;
            
        case CSelectCount:
            finalResult = [JRDBResult resultWithCount:[result unsignedIntegerValue]];break;
            
        case CSelect:
        case CSelectCustomized:
            finalResult = [JRDBResult resultWithArray:[result copy]];break;
        case CSelectSingle:
            finalResult = [JRDBResult resultWithObject:result];break;
            
        case COperationNone:
        default:
            finalResult = [JRDBResult resultWithBool:NO];
    }
    
    EXE_BLOCK(_completeBlock, self, finalResult);
    
    return finalResult;
    
}

- (JRDBResult *)exe {
    return [self exe:nil];
}

- (BOOL)updateResult {
    return self.exe.flag;
}

- (NSUInteger)count {
    return self.exe.count;
}

- (id<JRPersistent>)object {
    return self.exe.object;
}

- (NSArray<JRPersistent> *)list {
    return self.exe.list;
}

#pragma mark - Operation

static inline void __operationCheck(JRDBChain *self) {
    if (self.operation != COperationNone) {
        @throw [NSError errorWithDomain:@"multiple Chain operation error" code:0 userInfo:nil];
    }
}

static inline JRClassBlock __setTargetClassToSelf(JRDBChain *self, ChainOperation operation) {
    return ^(Class clazz) {
        __operationCheck(self);
        self->_operation = operation;
        self->_targetClazz = clazz;
        return self;
    };
}

- (JRClassBlock)CreateTable {
    return __setTargetClassToSelf(self, CCreateTable);
}

- (JRClassBlock)UpdateTable {
    return __setTargetClassToSelf(self, CUpdateTable);
}

- (JRClassBlock)DropTable {
    return __setTargetClassToSelf(self, CDropTable);
}

- (JRClassBlock)TruncateTable {
    return __setTargetClassToSelf(self, CTruncateTable);
}

- (JRClassBlock)DeleteAll {
    return __setTargetClassToSelf(self, CDeleteAll);
}

- (JRClassBlock)Select {
    return __setTargetClassToSelf(self, CSelect);
}

static inline JRArrayBlock __setTargetArrayToSelf(JRDBChain *self, ChainOperation operation) {
    return ^(NSArray *array) {
        __operationCheck(self);
        self->_operation = operation;
        if ([array.firstObject isKindOfClass:[NSArray class]]) {
            self->_targetArray = array.firstObject;
        }
        else if (array.count == 1) {
            self->_target = array.firstObject;
        } else {
            self->_targetArray = array;
        }
        return self;
    };
}

- (JRArrayBlock)Insert {
    return __setTargetArrayToSelf(self, CInsert);
}

- (JRArrayBlock)Update {
    return __setTargetArrayToSelf(self, CUpdate);
}

- (JRArrayBlock)Delete {
    return __setTargetArrayToSelf(self, CDelete);
}

- (JRArrayBlock)SaveOrUpdate {
    return __setTargetArrayToSelf(self, CSaveOrUpdate);
}

static inline JRObjectBlock __setTargetToSelf(JRDBChain *self, ChainOperation operation) {
    return ^(id one) {
        __operationCheck(self);
        self->_operation = operation;
        self->_target = one;
        return self;
    };
}

- (JRObjectBlock)InsertOne {
    return __setTargetToSelf(self, CInsert);
}

- (JRObjectBlock)UpdateOne {
    return __setTargetToSelf(self, CUpdate);
}

- (JRObjectBlock)DeleteOne {
    return __setTargetToSelf(self, CDelete);
}

- (JRObjectBlock)SaveOrUpdateOne {
    return __setTargetToSelf(self, CSaveOrUpdate);
}

#pragma mark - customized query

- (JRClassBlock)CountSelect {
    return ^(Class clazz) {
        __operationCheck(self);
        self->_operation = CSelectCount;
        self->_targetClazz= clazz;
        return self;
    };
}

- (JRArrayBlock)ColumnsSelect {
    return ^(NSArray *array) {
        __operationCheck(self);
        self->_operation = CSelectCustomized;
        self->_selectColumns = array;
        return self;
    };
}

#pragma mark - Property

- (JRObjectBlock)From {
    return ^(id from) {
        if ([from isKindOfClass:[JRDBChain class]]) {
            self->_subChain = from;
        } else if (object_isClass(from)) {
            self->_targetClazz = from;
            self->_tableName = [((Class)from) shortClazzName];
        }
        return self;
    };
}

- (JRLimitBlock)Limit {
    return ^(NSUInteger start, NSUInteger length){
        self->_limitIn = (JRLimit){start, length};
        return self;
    };
}

static inline JRObjectBlock __setObjectPropertyToSelf(JRDBChain *self, NSString *keypath) {
    return ^(id value) {
        [self setValue:value forKey:keypath];
        return self;
    };
}

- (JRObjectBlock)InDB {
    return __setObjectPropertyToSelf(self, J(db));
}

- (JRObjectBlock)Group {
    return __setObjectPropertyToSelf(self, J(groupBy));
}

- (JRObjectBlock)Order {
    return __setObjectPropertyToSelf(self, J(orderBy));
}

- (JRObjectBlock)Where {
    return __setObjectPropertyToSelf(self, J(whereString));
}

- (JRObjectBlock)WhereIdIs {
    return __setObjectPropertyToSelf(self, J(whereId));
}

- (JRObjectBlock)WherePKIs {
    return __setObjectPropertyToSelf(self, J(wherePK));
}

- (JRArrayBlock)Params {
    return __setObjectPropertyToSelf(self, J(parameters));
}

- (JRArrayBlock)Columns {
    return __setObjectPropertyToSelf(self, J(columnsArray));
}

- (JRArrayBlock)Ignore {
    return __setObjectPropertyToSelf(self, J(ignoreArray));
}

static inline JRBoolBlock __setBoolPropertyToSelf(JRDBChain *self, NSString *keypath) {
    return ^(BOOL value) {
        [self setValue:@(value) forKey:keypath];
        return self;
    };
}

- (JRBoolBlock)Recursive {
    return __setBoolPropertyToSelf(self, J(isRecursive));
}
- (instancetype)Recursively {
    return self.Recursive(YES);
}
- (instancetype)UnRecursively {
    return self.Recursive(NO);
}

- (JRBoolBlock)Sync {
    return __setBoolPropertyToSelf(self, J(isSync));
}
- (instancetype)UnSafely {
    return self.Sync(NO);
}
- (instancetype)Safely {
    return self.Sync(YES);
}

- (JRBoolBlock)Transaction {
    return __setBoolPropertyToSelf(self, J(useTransaction));
}
- (instancetype)NoTransaction {
    return self.Transaction(NO);
}
- (instancetype)Transactional {
    return self.Transaction(YES);
}

- (JRBoolBlock)Desc {
    return __setBoolPropertyToSelf(self, J(isDesc));
}
- (instancetype)Descend {
    return self.Desc(YES);
}
- (instancetype)Ascend {
    return self.Desc(NO);
}

- (JRBoolBlock)Cache {
    return __setBoolPropertyToSelf(self, J(useCache));
}
- (instancetype)Cached {
    return self.Cache(YES);
}
- (instancetype)NoCached {
    return self.Cache(NO);
}

- (JRCompleteBlock)Complete {
    return ^(JRDBChainComplete complete) {
        self->_completeBlock = complete;
        return self;
    };
}

#pragma mark - Other method

- (NSArray<JRQueryCondition *> *)queryCondition {
    
    NSAssert(!(_whereString.length && _whereId.length), @"where condition should not hold more than one!!!");
    NSAssert(!(_whereString.length && _wherePK), @"where condition should not hold more than one!!!");
    NSAssert(!(_whereId.length && _wherePK), @"where condition should not hold more than one!!!");

    NSArray *conditions = nil;
    if (_whereString.length) {
        conditions = @[[JRQueryCondition condition:_whereString args:_parameters type:JRQueryConditionTypeAnd]];
    } else if (_whereId.length) {
        conditions = @[[JRQueryCondition condition:@"_id = ?" args:@[_whereId] type:JRQueryConditionTypeAnd]];
    } else if (_wherePK) {
        NSString *pk = [_targetClazz jr_primaryKey];
        NSString *condition = [NSString stringWithFormat:@"%@ = ?", pk];
        conditions = @[[JRQueryCondition condition:condition args:@[_wherePK] type:JRQueryConditionTypeAnd]];
    }
    return conditions;
}

- (BOOL)isQuerySingle {
    return _whereId.length || _wherePK;
}

- (JRSql *)querySql {
    return [JRSqlGenerator sql4Chain:self];
}

#pragma mark - Setter Getter

- (Class<JRPersistent>)targetClazz {
    if (_targetClazz) {
        return _targetClazz;
    }
    if (_target) {
        return [_target class];
    }
    if ([_targetArray count]) {
        return [[_targetArray firstObject] class];
    }
    
    if (self.subChain) {
        return self.subChain.targetClazz;
    }
    return nil;
}

- (NSString *)limitString {
    if (_limitIn.start < 0 || _limitIn.length < 0) {
        return nil;
    }
    return [NSString stringWithFormat:@" limit %zd,%zd ", _limitIn.start, _limitIn.length];
}

- (NSArray<NSString *> *)selectColumns {
    if (!_selectColumns) {
        return nil;
    }
    
    NSMutableArray *arr = [_selectColumns mutableCopy];
    if (![arr containsObject:@"_ID"]) {
        [arr addObject:@"_ID"];
    }
    
    NSString *primaryKey = [((Class<JRPersistent>)self.targetClazz) jr_customPrimarykey];
    if (primaryKey.length && ![arr containsObject:primaryKey]) {
        [arr addObject:primaryKey];
    }
    _selectColumns = [arr copy];
    return _selectColumns;
}

#pragma mark - macro method will not execute
- (JRObjectBlock)FromJ {return nil;}
- (JRArrayBlock)ParamsJ {return nil;}
- (JRArrayBlock)IgnoreJ {return nil;}
- (JRArrayBlock)ColumnsJ {return nil;}
- (JRObjectBlock)WhereJ {return nil;}
- (JRObjectBlock)OrderJ {return nil;}
- (JRObjectBlock)GroupJ {return nil;}


@end

#pragma clang diagnostic pop