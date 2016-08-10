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

#define HistoryKey(key) \
static NSString * const key = @#key;

typedef NS_ENUM(NSInteger, OperationHistory) {
    OH_Insert = 1000,
    OH_Update,
    OH_Delete,
    OH_DeleteAll,
    OH_Select,
} ;

typedef NS_ENUM(NSInteger, PropertyHistory) {
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
} ;

@interface JRDBChain ()
@property (nonatomic, strong) NSMutableArray<NSNumber *> *history;///< 链式调用历史，用于检测
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

- (CreateTableBlock)CreateTable {
    return ^(Class<JRPersistent> clazz) {
        self->_operation = CCreateTable;
        self->_targetClazz = clazz;
        return self;
    };
}

- (UpdateTableBlock)UpdateTable {
    return ^(Class<JRPersistent> clazz) {
        self->_operation = CUpdateTable;
        self->_targetClazz = clazz;
        return self;
    };
}

- (DropTableBlock)DropTable {
    return ^(Class<JRPersistent> clazz) {
        self->_operation = CDropTable;
        self->_targetClazz = clazz;
        return self;
    };
}

- (TruncateTableBlock)TruncateTable {
    return ^(Class<JRPersistent> clazz) {
        self->_operation = CTruncateTable;
        self->_targetClazz = clazz;
        return self;
    };
}

- (DeleteAllBlock)DeleteAll {
    return ^(Class<JRPersistent> clazz) {
        self->_operation = CDeleteAll;
        self->_targetClazz = clazz;
        return self;
    };
}

static inline JRDBChain * setArrayToSelf(JRDBChain *self, NSArray *array) {
    if ([array.firstObject isKindOfClass:[NSArray class]]) {
        self->_targetArray = array.firstObject;
    }
    else if (array.count == 1) {
        self->_target = array.firstObject;
    } else {
        self->_targetArray = array;
    }
    return self;
}

- (InsertBlock)Insert {
    return ^(NSArray *array) {
        self->_operation = CInsert;
        setArrayToSelf(self, array);
        return self;
    };
}

- (UpdateBlock)Update {
    return ^(NSArray *array) {
        self->_operation = CUpdate;
        setArrayToSelf(self, array);
        return self;
    };
}

- (DeleteBlock)Delete {
    return ^(NSArray *array) {
        self->_operation = CUpdate;
        setArrayToSelf(self, array);
        return self;
    };
}

- (SaveOrUpdateBlock)SaveOrUpdate {
    return ^(NSArray *array) {
        self->_operation = CSaveOrUpdate;
        setArrayToSelf(self, array);
        return self;
    };
}

- (InsertOneBlock)InsertOne {
    return ^(id one) {
        self->_operation = CInsert;
        self->_target = one;
        return self;
    };
}

- (UpdateOneBlock)UpdateOne {
    return ^(id one) {
        self->_operation = CUpdate;
        self->_target = one;
        return self;
    };
}

- (DeleteOneBlock)DeleteOne {
    return ^(id one) {
        self->_operation = CDelete;
        self->_target = one;
        return self;
    };
}

- (SaveOrUpdateOneBlock)SaveOrUpdateOne {
    return ^(id one) {
        self->_operation = CSaveOrUpdate;
        self->_target = one;
        return self;
    };
}

#pragma mark - query

- (SelectClassBlock)Select {
    return ^(Class<JRPersistent> clazz) {
        self->_operation = CSelect;
        self->_targetClazz = clazz;
        return self;
    };
}


- (SelectColumnsBlock)ColumnsSelect {
    return ^(NSArray *array) {
        self->_operation = CSelectCustomized;
        self->_selectColumns = array;
        return self;
    };
}

- (SelectCountBlock)CountSelect {
    return ^(Class clazz) {
        self->_operation = CSelectCount;
        self->_targetClazz= clazz;
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

- (ObjectBlock)InDB {
    return ^(FMDatabase *db) {
        self->_db = db;
        return self;
    };
}

- (ObjectBlock)Group {
    return ^(NSString *groupBy) {
        self->_groupBy = groupBy;
        return self;
    };
}

- (ObjectBlock)Order {
    return ^(NSString *orderBy) {
        self->_orderBy = orderBy;
        return self;
    };
}

- (ObjectBlock)Where {
    return ^(NSString *where) {
        self->_whereString = where;
        return self;
    };
}

- (ObjectBlock)WhereIdIs {
    return ^(NSString *ID) {
        self->_whereId = ID;
        return self;
    };
}

- (ObjectBlock)WherePKIs {
    return ^(id pk) {
        self->_wherePK = pk;
        return self;
    };
}

- (BoolBlock)Recursive {
    return ^(BOOL isRecursive) {
        self->_isRecursive = isRecursive;
        return self;
    };
}

- (BoolBlock)Sync {
    return ^(BOOL isSync) {
        self->_isSync = isSync;
        return self;
    };
}

- (BoolBlock)Transaction {
    return ^(BOOL useTransaction) {
        self->_useTransaction = useTransaction;
        return self;
    };
}

- (BoolBlock)Desc {
    return ^(BOOL isDesc) {
        self->_isDesc = isDesc;
        return self;
    };
}

- (BoolBlock)Cache {
    return ^(BOOL useCache) {
        self->_useCache = useCache;
        return self;
    };
}

- (CompleteBlock)Complete {
    return ^(JRDBChainComplete complete) {
        self->_completeBlock = complete;
        return self;
    };
}

- (ObjectBlock)Params {
    return ^(NSArray *array) {
        self->_parameters = array;
        return self;
    };
}

- (ObjectBlock)Columns {
    return ^(NSArray *array) {
        self->_columnsArray = array;
        return self;
    };
}

- (ObjectBlock)Ignore {
    return ^(NSArray *array) {
        self->_ignoreArray = array;
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
