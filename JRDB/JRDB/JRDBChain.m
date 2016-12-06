//
//  JRDBChain.m
//  JRDB
//
//  Created by JMacMini on 16/7/11.
//  Copyright © 2016年 Jrwong. All rights reserved.
//

#import "JRDBChain.h"
#import "JRDBMgr.h"
#import <objc/runtime.h>
#import "NSObject+Reflect.h"
#import "JRSqlGenerator.h"
#import "JRActivatedProperty.h"

#import "FMDatabase+JRPersistentHandler.h"
#import "JRFMDBResultSetHandler.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Woverriding-method-mismatch"
#pragma clang diagnostic ignored "-Wmismatched-return-types"


@interface JRDBChain ()

@end

@implementation JRDBChain

@synthesize target         = _target;
@synthesize targetArray    = _targetArray;
@synthesize targetClazz    = _targetClazz;
@synthesize operation      = _operation;
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
@synthesize isDesc         = _isDesc;
@synthesize parameters     = _parameters;
@synthesize columnsArray   = _columnsArray;
@synthesize ignoreArray    = _ignoreArray;
@synthesize tableName      = _tableName;

- (instancetype)init {
    if (self = [super init]) {
        _isRecursive    = NO;
        _useTransaction = YES;
        _isSync         = YES;
        _db             = [JRDBMgr defaultDB];
        _limitIn        = (JRLimit){-1, -1};
    }
    return self;
}

- (JRDBResult *)exe {
    if (!self.target && !self.targetArray.count && !self.targetClazz) {
        NSLog(@"chain excute error, target or targetArray or targetClazz is nil");
        return nil;
    }
    
    if ([self isQuerySingle]) {
        _operation = CSelectSingle;
    }
    
    id result;
    switch (_operation) {
        case CSelect:
        case CSelectSingle:
        {
            if (self.isRecursive)
                result = [self jr_executeQueryChainRecusively];
            else
                result = [self jr_executeQueryChain];
        }
        break;
            
        case CSelectCustomized:
        case CSelectCount:
        {
            result = [self jr_executeCustomizedQueryChain];
        }
        break;
            
        case CCreateTable:
        case CDropTable:
        case CTruncateTable:
        case CUpdateTable:
            result = @([self jr_executeTableOperation]);
            break;
        default:
        {
            if (self.isRecursive)
                result = @([self jr_executeUpdateChainRecusively]);
            else
                result = @([self jr_executeUpdateChain]);
        }
    }
    
    JRDBResult *finalResult;
    switch (self.operation) {
        case CSelectCount:
            finalResult = [JRDBResult resultWithCount:[result unsignedIntegerValue]];
            break;
            
        case CSelect:
        case CSelectCustomized:
            finalResult = [JRDBResult resultWithArray:[result copy]];
            break;
        case CSelectSingle:
            finalResult = [JRDBResult resultWithObject:result];
            break;
            
        case CCreateTable:
        case CUpdateTable:
        case CDropTable:
        case CTruncateTable:
        case CInsert:
        case CUpdate:
        case CDeleteAll:
        case CDelete:
        case CSaveOrUpdate:
        case COperationNone:
        default:
            finalResult = [JRDBResult resultWithBool:[result boolValue]];
            break;
    }
    
    return finalResult;
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

- (NSArray *)list {
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
            self->_tableName = [((Class<JRPersistent>)from) jr_tableName];
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
        if (
            (![keypath isEqualToString:J(columnsArray)]
             &&![keypath isEqualToString:J(ignoreArray)]
             )
            &&!value) {
            NSLog(@"passing a nil value to keypath: %@", keypath);
            assert(NO);
        }
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

#pragma mark - Other method

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

#pragma clang diagnostic pop

#pragma mark - execution

- (id)jr_executeQueryChain {
    NSAssert(!self.selectColumns.count, @"selectColumns should not has count in normal query");
    id result = [_db jr_getByJRSql:self.querySql sync:self.isSync resultClazz:self.targetClazz columns:self.selectColumns];
    return [self _handleQueryResult:result];
}

- (id)jr_executeCustomizedQueryChain {
    return
    [_db jr_executeSync:self.isSync block:^id _Nullable(id<JRPersistentHandler>  _Nonnull handler) {
        FMResultSet *resultSet = [handler jr_executeQuery:self.querySql];
        id result = [JRFMDBResultSetHandler handleResultSet:resultSet forChain:self];
        return result;
    }];
}

- (BOOL)jr_executeUpdateChain {
    
    if (self.operation == CInsert) {
        if (self.targetArray) {
            return [_db jr_saveObjects:self.targetArray useTransaction:self.useTransaction synchronized:self.isSync];
        }
        return [_db jr_saveOne:self.target useTransaction:self.useTransaction synchronized:self.isSync];
    }
    else if (self.operation == CUpdate) {
        if (self.targetArray) {
            return [_db jr_updateObjects:self.targetArray columns:[self _needUpdateColumns] useTransaction:self.useTransaction synchronized:self.isSync];
        }
        return [_db jr_updateOne:self.target columns:[self _needUpdateColumns] useTransaction:self.useTransaction synchronized:self.isSync];
    }
    else if (self.operation == CDelete) {
        if (self.targetArray) {
            return [_db jr_deleteObjects:self.targetArray useTransaction:self.useTransaction synchronized:self.isSync];
        }
        return [_db jr_deleteOne:self.target useTransaction:self.useTransaction synchronized:self.isSync];
    }
    else if (self.operation == CSaveOrUpdate) {
        if (self.targetArray) {
            return [_db jr_saveOrUpdateObjects:self.targetArray useTransaction:self.useTransaction synchronized:self.isSync];
        }
        return [_db jr_saveOrUpdateOne:self.target useTransaction:self.useTransaction synchronized:self.isSync];
    }
    else if (self.operation == CDeleteAll) {
        return [_db jr_deleteAll:self.targetClazz useTransaction:self.useTransaction synchronized:self.isSync];
    }
    else {
        NSAssert(NO, @"%s :%@", __FUNCTION__, @"chain operation should be Inset or Update or Delete or DeleteAll");
        return NO;
    }
}

- (BOOL)jr_executeTableOperation {
    if (self.operation == CCreateTable) {
        return [_db jr_createTable4Clazz:self.targetClazz synchronized:self.isSync];
    }
    else if (self.operation == CUpdateTable) {
        return [_db jr_updateTable4Clazz:self.targetClazz synchronized:self.isSync];
    }
    else if (self.operation == CDropTable) {
        return [_db jr_dropTable4Clazz:self.targetClazz synchronized:self.isSync];
    }
    else if (self.operation == CTruncateTable) {
        return [_db jr_truncateTable4Clazz:self.targetClazz synchronized:self.isSync];
    }
    else {
        NSAssert(NO, @"%s :%@", __FUNCTION__, @"chain operation is not the table operation");
        return NO;
    }
}


- (id)_handleQueryResult:(NSArray *)result {
    return self.operation == CSelectSingle ? [result firstObject] : result;
}

- (NSArray *)_needUpdateColumns {
    NSAssert(!(self.columnsArray.count && self.ignoreArray.count), @"colums and ignore should not use at the same chain !!");
    NSMutableArray *columns = [NSMutableArray array];
    if (self.columnsArray.count) {
        return self.columnsArray;
    }
    else if (self.ignoreArray.count) {
        Class<JRPersistent> clazz = self.targetClazz;
        [[clazz jr_activatedProperties] enumerateObjectsUsingBlock:^(JRActivatedProperty * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (![self.ignoreArray containsObject:obj.ivarName]) {
                [columns addObject:obj.ivarName];
            }
        }];
    }
    return columns.count ? columns : nil;
}

@end


@implementation JRDBChain (Recursive)

- (id)jr_executeQueryChainRecusively {
    NSAssert(!self.selectColumns.count, @"selectColumns should not has count in normal query");
    id result = [_db jr_findByJRSql:self.querySql sync:self.isSync resultClazz:self.targetClazz columns:self.selectColumns];
    return [self _handleQueryResult:result];
}

- (BOOL)jr_executeUpdateChainRecusively {
    if (self.operation == CInsert) {
        if (self.targetArray) {
            return [_db jr_saveObjectsRecursively:self.targetArray useTransaction:self.useTransaction synchronized:self.isSync];
        }
        return [_db jr_saveOneRecursively:self.target useTransaction:self.useTransaction synchronized:self.isSync];
    }
    else if (self.operation == CUpdate) {
        if (self.targetArray) {
            return [_db jr_updateObjectsRecursively:self.targetArray columns:[self _needUpdateColumns] useTransaction:self.useTransaction synchronized:self.isSync];
        }
        return [_db jr_updateOneRecursively:self.target columns:[self _needUpdateColumns] useTransaction:self.useTransaction synchronized:self.isSync];
    }
    else if (self.operation == CDelete) {
        if (self.targetArray) {
            return [_db jr_deleteObjectsRecursively:self.targetArray useTransaction:self.useTransaction synchronized:self.isSync];
        }
        return [_db jr_deleteOneRecursively:self.target useTransaction:self.useTransaction synchronized:self.isSync];
    }
    else if (self.operation == CSaveOrUpdate) {
        if (self.targetArray) {
            return [_db jr_saveOrUpdateObjectsRecursively:self.targetArray useTransaction:self.useTransaction synchronized:self.isSync];
        }
        return [_db jr_saveOrUpdateOneRecursively:self.target useTransaction:self.useTransaction synchronized:self.isSync];
    }
    else if (self.operation == CDeleteAll) {
        return [_db jr_deleteAllRecursively:self.targetClazz useTransaction:self.useTransaction synchronized:self.isSync];
    }
    else {
        NSAssert(NO, @"%s :%@", __FUNCTION__, @"chain operation should be Inset or Update or Delete or DeleteAll");
        return NO;
    }
}

@end
