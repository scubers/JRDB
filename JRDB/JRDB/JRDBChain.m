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
@import FMDB;

#define BlockPropertyImpl(_type_, _methodName_, _propName_)\
@synthesize _propName_ = _##_propName_;\
- (JRDBChain *(^)(_type_ prop))_methodName_ {\
    jr_weak(self);\
    return ^JRDBChain *(_type_ prop){\
        jr_strong(self);\
        self->_##_propName_ = prop;\
        return self;\
    };\
}

#define OperationBlockForArrayImpl(_block_, _methodName_, _operation_)\
- (_block_)_methodName_ {\
    jr_weak(self);\
    return ^JRDBChain *(NSArray<id<JRPersistent>> *array) {\
        jr_strong(self);\
        self->_operation = _operation_;\
        if (array.count <= 1) {\
            self->_target = array.firstObject;\
        } else {\
            self->_targetArray = array;\
        }\
        return self;\
    };\
}

#define OperationBlockForClazzImpl(_block_, _methodName_, _operation_)\
- (_block_)_methodName_ {\
    jr_weak(self);\
    return ^JRDBChain *(Class<JRPersistent> clazz) {\
        jr_strong(self);\
        self->_operation = _operation_;\
        self->_targetClazz = clazz;\
        return self;\
    };\
}


#define ArrrayPropertyImpl(_method_,_propName_)                        \
@synthesize _propName_ = _##_propName_;\
- (JRDBChain *(^)(id, ...))_method_ {                 \
    jr_weak(self);                              \
    return ^JRDBChain *(id obj, ...) {                  \
        jr_strong(self);                                \
        if ([obj isKindOfClass:[NSArray class]]) {\
            self->_##_propName_ = obj;               \
        } else {\
            NSMutableArray *args = [NSMutableArray array];  \
            va_list ap;                                     \
            va_start(ap, obj);                              \
            id arg;                                         \
            while( (arg = va_arg(ap,id)) )                      \
            {                       \
                if ( arg ){                 \
                [args addObject:arg];       \
                }   \
            }                   \
            va_end(ap);                             \
            [args insertObject:obj atIndex:0];              \
            self->_##_propName_ = args;               \
        }\
        return self;                \
    };              \
}

#define HistoryKey(key) \
static NSString * const key = @#key;

typedef enum {
    OH_Insert = 1000,
    OH_Update,
    OH_Delete,
    OH_DeleteAll,
    OH_Select,
} OperationHistory;

typedef enum {
    PH_InDB = 2000,
    PH_From,
    PH_Where,
    PH_Group,
    PH_Order,
    PH_Desc,
    PH_Limit,

    PH_Recursive,
    PH_NowInMain,
    PH_Transaction,
    PH_Complete,

    PH_Params,
    PH_Columns,
    PH_Ignore,
} PropertyHistory;

@interface JRDBChain ()

@property (nonatomic, strong) NSMutableArray<NSNumber *> *history;///< 链式调用历史，用于检测

@property (nonatomic, strong) id result;///< 存储执行结果

@end

@implementation JRDBChain

@synthesize target      = _target;
@synthesize operation   = _operation;
@synthesize targetClazz = _targetClazz;

- (instancetype)init {
    if (self = [super init]) {
        _isRecursive    = NO;
        _useTransaction = YES;
        _useCache       = NO;
        _db             = [JRDBMgr defaultDB];
        _isSync         = YES;
        _limitIn        = (JRLimit){-1, -1};
    }
    return self;
}

- (id)exe:(JRDBChainComplete)complete {

    if (!self.target && !self.targetArray.count && !self.targetClazz) {
        NSLog(@"chain excute error, target are nil");
        return nil;
    }
    
    _completeBlock = complete;

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

- (SelectBlock)Select {
    jr_weak(self);
    return ^JRDBChain *(id first, ...) {
        jr_strong(self);
        if (object_isClass(first)) {
            self->_operation = CSelect;
            self->_targetClazz = first;
        }
        else if([first isEqualToString:JRCount]) {
            self->_operation = CSelectCount;
        }
        else {
            self->_operation = CSelectCustomized;
            if ([first isKindOfClass:[NSArray class]]) {
                self->_selectColumns = first;
            } else {
                NSMutableArray *args = [NSMutableArray array];
                va_list ap;
                va_start(ap, first);
                id arg;
                while( (arg = va_arg(ap,id)) )
                {
                    if ( arg ){
                        [args addObject:arg];
                    }
                }
                va_end(ap);
                [args insertObject:first atIndex:0];
                self->_selectColumns = args;
            }
        }
        return self;
    };
}


OperationBlockForClazzImpl(CreateTableBlock, CreateTable, CCreateTable)
OperationBlockForClazzImpl(UpdateTableBlock, UpdateTable, CUpdateTable)
OperationBlockForClazzImpl(DropTableBlock, DropTable, CDropTable)
OperationBlockForClazzImpl(TruncateTableBlock, TruncateTable, CTruncateTable)

OperationBlockForClazzImpl(DeleteAllBlock, DeleteAll, CDeleteAll)

OperationBlockForArrayImpl(InsertBlock, Insert, CInsert)
OperationBlockForArrayImpl(UpdateBlock, Update, CUpdate)
OperationBlockForArrayImpl(DeleteBlock, Delete, CDelete)
OperationBlockForArrayImpl(SaveOrUpdateBlock, SaveOrUpdate, CSaveOrUpdate)

#pragma mark - Property

- (JRDBChain *(^)(id))From {
    jr_weak(self);
    return ^JRDBChain *(id from) {
        jr_strong(self);
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

- (JRDBChain *(^)(NSUInteger, NSUInteger))Limit {
    jr_weak(self);
    return ^JRDBChain *(NSUInteger start, NSUInteger length){
        jr_strong(self);
        self->_limitIn = (JRLimit){start, length};
        return self;
    };
}

BlockPropertyImpl(FMDatabase *, InDB, db)
BlockPropertyImpl(NSString *, Group, groupBy)
BlockPropertyImpl(NSString *, Order, orderBy)
BlockPropertyImpl(NSString *, Where, whereString)
BlockPropertyImpl(BOOL, Recursive, isRecursive)
BlockPropertyImpl(BOOL, Sync, isSync)
BlockPropertyImpl(BOOL, Trasaction, useTransaction)
BlockPropertyImpl(BOOL, Desc, isDesc)
BlockPropertyImpl(BOOL, Cache, useCache)
BlockPropertyImpl(JRDBChainComplete, Complete, completeBlock)


ArrrayPropertyImpl(Params, parameters)
ArrrayPropertyImpl(Columns, columnsArray)
ArrrayPropertyImpl(Ignore, ignoreArray)


#pragma mark - Other method

- (NSArray<JRQueryCondition *> *)queryCondition {
    NSArray *conditions = nil;
    if (_whereString.length) {
        conditions = @[[JRQueryCondition condition:_whereString args:_parameters type:JRQueryConditionTypeAnd]];
    }
    return conditions;
}


- (NSArray *)variableListToArray:(va_list)valist {
    NSMutableArray *args = [NSMutableArray array];
    id arg;
    while( (arg = va_arg(valist,id)) )
    {
        if ( arg ){
            [args addObject:arg];
        }
    }
    self->_selectColumns = args;
    return args;
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

- (NSMutableArray<NSNumber *> *)history {
    if (!_history) {
        _history = [NSMutableArray array];
    }
    return _history;
}

#pragma mark - private method
- (BOOL)_checkValid:(NSNumber *)action {
    if ([self _isOperationBlock:action]) {
        return [self _validOperation:action];
    } else {
        return [self _validOperation:action];
    }
}

- (BOOL)_isOperationBlock:(NSNumber *)action {
    return [action intValue] < 2000;
}

- (BOOL)_validOperation:(NSNumber *)action {
    for (NSNumber *historyAction in self.history) {
        if ([historyAction intValue] > 999 && [historyAction intValue] < 2000) {
            return NO;
        }
    }
    return YES;
}

- (BOOL)_validProperty:(NSNumber *)action {
    switch ([action intValue]) {
        case PH_Columns:
            break;
        case PH_Ignore:
            break;
        case PH_Where:break;
        case PH_Group:break;
        case PH_Order:break;
        case PH_InDB:break;
        case PH_From:break;
        case PH_Desc:break;
        case PH_Limit:break;
        case PH_Params:break;
        case PH_Recursive:
        case PH_NowInMain:
        case PH_Complete:
        case PH_Transaction:
            return YES;
        default:return NO;
    }
    return NO;
}

@end
