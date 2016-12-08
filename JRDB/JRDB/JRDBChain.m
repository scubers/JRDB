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
        _limitIn        = (JRLimit){-1, -1};
    }
    return self;
}

- (JRDBResult *)exe {
    
    if (!_db) _db = [JRDBMgr shareInstance].getHandler; // 延迟加载数据库
    
    if (!self.target && !self.targetArray.count && !self.targetClazz) {
        NSLog(@"chain excute error, target or targetArray or targetClazz is nil");
        return nil;
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
    
    ChainOperation op = [self getRealOperationWithResult:result];
    
    JRDBResult *finalResult;
    switch (op) {
        case CSelectCount:
            finalResult = [JRDBResult resultWithCount:[result unsignedIntegerValue]];
            break;
            
        case CSelect:
        case CSelectCustomized:
            finalResult = [JRDBResult resultWithArray:[result copy]];
            break;
        case CSelectSingle:
            finalResult = [JRDBResult resultWithObject:[result firstObject]];
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

- (ChainOperation)getRealOperationWithResult:(id)result {
    switch (_operation) {
        case CSelectCustomized:
        case CSelect: {
            if (_wherePK || _whereId) {
                return CSelectSingle;
            }
            break;
        }
        default:
            break;
    }
    return _operation;
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

- (JRClassBlock)__setTargetClassToSelfWithOperation:(ChainOperation)operation block:(void (^)(Class clazz))block {
    return ^(Class clazz) {
        __operationCheck(self);
        self->_operation = operation;
        self->_targetClazz = clazz;
        return self;
    };
}

- (JRClassBlock)CreateTable {
    return [self __setTargetClassToSelfWithOperation:CCreateTable block:^(__unsafe_unretained Class clazz) {
        
    }];
}

- (JRClassBlock)UpdateTable {
    return [self __setTargetClassToSelfWithOperation:CUpdateTable block:^(__unsafe_unretained Class clazz) {
        
    }];
}

- (JRClassBlock)DropTable {
    return [self __setTargetClassToSelfWithOperation:CDropTable block:^(__unsafe_unretained Class clazz) {
        
    }];
}

- (JRClassBlock)TruncateTable {
    return [self __setTargetClassToSelfWithOperation:CTruncateTable block:^(__unsafe_unretained Class clazz) {
        
    }];
}

- (JRClassBlock)DeleteAll {
    return [self __setTargetClassToSelfWithOperation:CDeleteAll block:^(__unsafe_unretained Class clazz) {
        
    }];
}

- (JRClassBlock)Select {
    return [self __setTargetClassToSelfWithOperation:CSelect block:^(__unsafe_unretained Class clazz) {
        
    }];
}

- (JRArrayBlock)__setTargetArrayToSelfWithOperation:(ChainOperation)operation block:(void (^)(id obj))block {
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
    return [self __setTargetArrayToSelfWithOperation:CInsert block:^(id obj) {
        
    }];
}

- (JRArrayBlock)Update {
    return [self __setTargetArrayToSelfWithOperation:CUpdate block:^(id obj) {
        
    }];
}

- (JRArrayBlock)Delete {
    return [self __setTargetArrayToSelfWithOperation:CDelete block:^(id obj) {
        
    }];
}

- (JRArrayBlock)SaveOrUpdate {
    return [self __setTargetArrayToSelfWithOperation:CSaveOrUpdate block:^(id obj) {
        
    }];
}

- (JRObjectBlock)__setTargetToSelfWithOperation:(ChainOperation)operation block:(void (^)(id obj))block {
    return ^(id one) {
        __operationCheck(self);
        self->_operation = operation;
        self->_target = one;
        return self;
    };
}

- (JRObjectBlock)InsertOne {
    return [self __setTargetToSelfWithOperation:CInsert block:^(id obj) {
        
    }];
}

- (JRObjectBlock)UpdateOne {
    return [self __setTargetToSelfWithOperation:CUpdate block:^(id obj) {
        
    }];
}

- (JRObjectBlock)DeleteOne {
    return [self __setTargetToSelfWithOperation:CDelete block:^(id obj) {
        
    }];
}

- (JRObjectBlock)SaveOrUpdateOne {
    return [self __setTargetToSelfWithOperation:CSaveOrUpdate block:^(id obj) {
        
    }];
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

- (JRObjectBlock)__setObjectPropertyToSelfWithKeypath:(NSString *)keypath block:(void (^)(id obj))block {
    return ^(id value) {
        [self setValue:value forKey:keypath];
        if (block) {
            block(value);
        }
        return self;
    };
}

- (JRObjectBlock)InDB {
    return [self __setObjectPropertyToSelfWithKeypath:J(db) block:^(id obj) {
        if (!obj) {
            NSLog(@"[InDB] should no pass a nil value");
            assert(false);
        }
    }];
}

- (JRObjectBlock)Group {
    return [self __setObjectPropertyToSelfWithKeypath:J(groupBy) block:^(id obj) {
        
    }];
}

- (JRObjectBlock)Order {
    return [self __setObjectPropertyToSelfWithKeypath:J(orderBy) block:^(id obj) {
        
    }];
}

- (JRObjectBlock)Where {
    return [self __setObjectPropertyToSelfWithKeypath:J(whereString) block:^(id obj) {
        
    }];
}

- (JRObjectBlock)WhereIdIs {
    return [self __setObjectPropertyToSelfWithKeypath:J(whereId) block:^(id obj) {
        if (!obj) {
            NSLog(@"[WhereIdIs] should no pass a nil value");
            assert(false);
        }
    }];
}

- (JRObjectBlock)WherePKIs {
    return [self __setObjectPropertyToSelfWithKeypath:J(wherePK) block:^(id obj) {
        if (!obj) {
            NSLog(@"[WherePKIs] pk should no be nil");
            assert(false);
        }
    }];
}

- (JRArrayBlock)Params {
    return [self __setObjectPropertyToSelfWithKeypath:J(parameters) block:^(id obj) {
        
    }];
}

- (JRArrayBlock)Columns {
    return [self __setObjectPropertyToSelfWithKeypath:J(columnsArray) block:^(id obj) {
        
    }];
}

- (JRArrayBlock)Ignore {
    return [self __setObjectPropertyToSelfWithKeypath:J(ignoreArray) block:^(id obj) {
        
    }];
}

- (JRBoolBlock)__setBoolPropertyToSelfWithKeypath:(NSString *)keypath block:(void (^)(BOOL value))block {
    return ^(BOOL value) {
        [self setValue:@(value) forKey:keypath];
        if (block) {
            block(value);
        }
        return self;
    };
}

- (JRBoolBlock)Recursive {
    return [self __setBoolPropertyToSelfWithKeypath:J(isRecursive) block:^(BOOL value) {
        
    }];
}
- (instancetype)Recursively {
    return self.Recursive(YES);
}
- (instancetype)UnRecursively {
    return self.Recursive(NO);
}

- (JRBoolBlock)Sync {
    return [self __setBoolPropertyToSelfWithKeypath:J(isSync) block:^(BOOL value) {
        
    }];
}
- (instancetype)UnSafely {
    return self.Sync(NO);
}
- (instancetype)Safely {
    return self.Sync(YES);
}

- (JRBoolBlock)Transaction {
    return [self __setBoolPropertyToSelfWithKeypath:J(useTransaction) block:^(BOOL value) {
        
    }];
}
- (instancetype)NoTransaction {
    return self.Transaction(NO);
}
- (instancetype)Transactional {
    return self.Transaction(YES);
}

- (JRBoolBlock)Desc {
    return [self __setBoolPropertyToSelfWithKeypath:J(isDesc) block:^(BOOL value) {
        
    }];
}
- (instancetype)Descend {
    return self.Desc(YES);
}
- (instancetype)Ascend {
    return self.Desc(NO);
}

#pragma mark - conditions

- (NSMutableArray<JRDBChainCondition *> *)conditions {
    if (!_conditions) {
        _conditions = [NSMutableArray array];
    }
    return _conditions;
}

- (JRDBChainCondition * _Nonnull (^)(NSString * _Nonnull))And {
    JRDBChainCondition *con = [JRDBChainCondition chainConditionWithChain:self type:JRDBChainConditionType_And];
    [self.conditions addObject:con];
    return con.key;
}

- (JRDBChainCondition * _Nonnull (^)(id _Nonnull))Or {
    JRDBChainCondition *con = [JRDBChainCondition chainConditionWithChain:self type:JRDBChainConditionType_Or];
    [self.conditions addObject:con];
    return con.key;
}

#pragma mark - Other method

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
    if (![arr containsObject:DBIDKey]) {
        [arr addObject:DBIDKey];
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
- (JRDBChainCondition * (^)(NSString *))AndJ {return nil;}
- (JRDBChainCondition * (^)(id))OrJ {return nil;}

#pragma clang diagnostic pop

#pragma mark - execution

- (id)jr_executeQueryChain {
    NSAssert(!self.selectColumns.count, @"selectColumns should not has count in normal query");
    return [_db jr_getByJRSql:self.querySql sync:self.isSync resultClazz:self.targetClazz columns:self.selectColumns];
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

- (NSArray *)_needUpdateColumns {
    NSAssert(!(self.columnsArray.count && self.ignoreArray.count), @"colums and ignore should not use at the same chain !!");
    NSMutableArray *columns = [NSMutableArray array];
    if (self.columnsArray.count) {
        return self.columnsArray;
    }
    else if (self.ignoreArray.count) {
        Class<JRPersistent> clazz = self.targetClazz;
        [[clazz jr_activatedProperties] enumerateObjectsUsingBlock:^(JRActivatedProperty * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (![self.ignoreArray containsObject:obj.propertyName]) {
                [columns addObject:obj.propertyName];
            }
        }];
    }
    return columns.count ? columns : nil;
}

@end


@implementation JRDBChain (Recursive)

- (id)jr_executeQueryChainRecusively {
    NSAssert(!self.selectColumns.count, @"selectColumns should not has count in normal query");
    return [_db jr_findByJRSql:self.querySql sync:self.isSync resultClazz:self.targetClazz columns:self.selectColumns];
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
