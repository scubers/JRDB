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

@interface JRDBChain ()
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

- (id)exe:(JRDBChainComplete)complete {

    if (!self.target && !self.targetArray.count && !self.targetClazz) {
        NSLog(@"chain excute error, target are nil");
        return nil;
    }
    
    if (complete) {
        _completeBlock = complete;
    }

    if (self.operation == CSelect) {
        id result = [_db jr_executeQueryChain:self complete:complete];
        return result;
    }
    else if(self.operation == CSelectCustomized || self.operation == CSelectCount) {
        id result = [_db jr_executeCustomizedQueryChain:self complete:complete];
        return result;
    }
    else {
        return @([_db jr_executeUpdateChain:self complete:complete]);
    }
}

#pragma mark - Operation

static inline void __operationCheck(JRDBChain *self) {
    if (self.operation != COperationNone) {
        @throw [NSError errorWithDomain:@"multiple Chain operation error" code:0 userInfo:nil];
    }
}

static inline ClassBlock __setTargetClassToSelf(JRDBChain *self, ChainOperation operation) {
    return ^(Class clazz) {
        __operationCheck(self);
        self->_operation = operation;
        self->_targetClazz = clazz;
        return self;
    };
}

- (ClassBlock)CreateTable {
    return __setTargetClassToSelf(self, CCreateTable);
}

- (ClassBlock)UpdateTable {
    return __setTargetClassToSelf(self, CUpdateTable);
}

- (ClassBlock)DropTable {
    return __setTargetClassToSelf(self, CDropTable);
}

- (ClassBlock)TruncateTable {
    return __setTargetClassToSelf(self, CTruncateTable);
}

- (ClassBlock)DeleteAll {
    return __setTargetClassToSelf(self, CDeleteAll);
}

- (ClassBlock)Select {
    return __setTargetClassToSelf(self, CSelect);
}

static inline ArrayBlock __setTargetArrayToSelf(JRDBChain *self, ChainOperation operation) {
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

- (ArrayBlock)Insert {
    return __setTargetArrayToSelf(self, CInsert);
}

- (ArrayBlock)Update {
    return __setTargetArrayToSelf(self, CUpdate);
}

- (ArrayBlock)Delete {
    return __setTargetArrayToSelf(self, CDelete);
}

- (ArrayBlock)SaveOrUpdate {
    return __setTargetArrayToSelf(self, CSaveOrUpdate);
}

static inline ObjectBlock __setTargetToSelf(JRDBChain *self, ChainOperation operation) {
    return ^(id one) {
        __operationCheck(self);
        self->_operation = operation;
        self->_target = one;
        return self;
    };
}

- (ObjectBlock)InsertOne {
    return __setTargetToSelf(self, CInsert);
}

- (ObjectBlock)UpdateOne {
    return __setTargetToSelf(self, CUpdate);
}

- (ObjectBlock)DeleteOne {
    return __setTargetToSelf(self, CDelete);
}

- (ObjectBlock)SaveOrUpdateOne {
    return __setTargetToSelf(self, CSaveOrUpdate);
}

#pragma mark - customized query

- (ClassBlock)CountSelect {
    return ^(Class clazz) {
        __operationCheck(self);
        self->_operation = CSelectCount;
        self->_targetClazz= clazz;
        return self;
    };
}

- (ArrayBlock)ColumnsSelect {
    return ^(NSArray *array) {
        __operationCheck(self);
        self->_operation = CSelectCustomized;
        self->_selectColumns = array;
        return self;
    };
}

#pragma mark - Property

- (ObjectBlock)From {
    return ^(id from) {
        if (object_isClass(from)) {
            self->_targetClazz = from;
            self->_tableName = [((Class)from) shortClazzName];
        } else {
            self->_tableName = from;
            Class clazz = NSClassFromString(from);
            if (clazz) {
                self->_targetClazz = clazz;
            }
        }
        return self;
    };
}

- (LimitBlock)Limit {
    return ^(NSUInteger start, NSUInteger length){
        self->_limitIn = (JRLimit){start, length};
        return self;
    };
}

static inline ObjectBlock __setObjectPropertyToSelf(JRDBChain *self, NSString *keypath) {
    return ^(id value) {
        [self setValue:value forKey:keypath];
        return self;
    };
}

- (ObjectBlock)InDB {
    return __setObjectPropertyToSelf(self, J(JRDBChain, db));
}

- (ObjectBlock)Group {
    return __setObjectPropertyToSelf(self, J(JRDBChain, groupBy));
}

- (ObjectBlock)Order {
    return __setObjectPropertyToSelf(self, J(JRDBChain, orderBy));
}

- (ObjectBlock)Where {
    return __setObjectPropertyToSelf(self, J(JRDBChain, whereString));
}

- (ObjectBlock)WhereIdIs {
    return __setObjectPropertyToSelf(self, J(JRDBChain, whereId));
}

- (ObjectBlock)WherePKIs {
    return __setObjectPropertyToSelf(self, J(JRDBChain, wherePK));
}

- (ArrayBlock)Params {
    return __setObjectPropertyToSelf(self, J(JRDBChain, parameters));
}

- (ArrayBlock)Columns {
    return __setObjectPropertyToSelf(self, J(JRDBChain, columnsArray));
}

- (ArrayBlock)Ignore {
    return __setObjectPropertyToSelf(self, J(JRDBChain, ignoreArray));
}

static inline BoolBlock __setBoolPropertyToSelf(JRDBChain *self, NSString *keypath) {
    return ^(BOOL value) {
        [self setValue:@(value) forKey:keypath];
        return self;
    };
}

- (BoolBlock)Recursive {
    return __setBoolPropertyToSelf(self, J(JRDBChain, isRecursive));
}

- (BoolBlock)Sync {
    return __setBoolPropertyToSelf(self, J(JRDBChain, isSync));
}

- (BoolBlock)Transaction {
    return __setBoolPropertyToSelf(self, J(JRDBChain, useTransaction));
}

- (BoolBlock)Desc {
    return __setBoolPropertyToSelf(self, J(JRDBChain, isDesc));
}

- (BoolBlock)Cache {
    return __setBoolPropertyToSelf(self, J(JRDBChain, useCache));
}

- (CompleteBlock)Complete {
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
    return nil;
}

- (NSString *)limitString {
    if (_limitIn.start < 0 || _limitIn.length < 0) {
        return nil;
    }
    return [NSString stringWithFormat:@" limit %zd,%zd ", _limitIn.start, _limitIn.length];
}


@end
