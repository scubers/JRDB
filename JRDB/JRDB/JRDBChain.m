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

#define OperationBlockImpl(_block_, _methodName_, _operation_)\
- (_block_)_methodName_ {\
    jr_weak(self);\
    return ^JRDBChain *(id obj){\
        jr_strong(self);\
        self->_operation = _operation_;\
        self->_target = obj;\
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

@interface JRDBChain ()

@property (nonatomic, strong) NSMutableArray *history;
@property (nonatomic, strong) id             result;

@end

@implementation JRDBChain

@synthesize target    = _target;
@synthesize operation = _operation;

- (instancetype)init {
    if (self = [super init]) {
        _isRecursive = YES;
        _isNowInMain = YES;
        _useTransaction = YES;
        _db = [JRDBMgr defaultDB];
    }
    return self;
}

- (id)exe:(JRDBChainComplete)complete {
    _completeBlock = complete;
    if (self.operation == CSelect) {
        id result = [_db jr_executeQueryChain:self];
        EXE_BLOCK(_completeBlock, self, result);
        return result;
    }
    else if(self.operation == CSelectCustomized || self.operation == CSelectCount) {
        id result = [_db jr_executeCustomizedQueryChain:self];
        EXE_BLOCK(_completeBlock, self, result);
        return result;
    }
    else if(self.isNowInMain) {
        BOOL ret = [_db jr_executeUpdateChain:self];
        EXE_BLOCK(_completeBlock, self, @(ret));
        return @(ret);
    } else {
        [_db jr_executeUpdateChain:self complete:^(BOOL success) {
            EXE_BLOCK(self.completeBlock, self, @(success));
        }];
        return nil;
    }
}

- (SelectBlock)Select {
    jr_weak(self);
    return ^JRDBChain *(id first, ...) {
        jr_strong(self);
        if (object_isClass(first)) {
            self->_operation = CSelect;
            self->_target = first;
        }
        else if([first isEqualToString:JRCount]) {
            self->_operation = CSelectCount;
        }
        else {
            self->_operation = CSelectCustomized;
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
        return self;
    };
}

- (JRDBChain *(^)(id))From {
    jr_weak(self);
    return ^JRDBChain *(id from) {
        jr_strong(self);
        if (object_isClass(from)) {
            self->_target = from;
            self->_tableName = [((Class)from) shortClazzName];
        } else {
            self->_tableName = from;
            Class clazz = NSClassFromString(from);
            if (clazz) {
                self->_target = clazz;
            }
        }
        return self;
    };
}

OperationBlockImpl(InsertBlock, Insert, CInsert)
OperationBlockImpl(UpdateBlock, Update, CUpdate)
OperationBlockImpl(DeleteBlock, Delete, CDelete)
OperationBlockImpl(DeleteAllBlock, DeleteAll, CDeleteAll)


BlockPropertyImpl(FMDatabase *, InDB, db)
BlockPropertyImpl(NSString *, Group, groupBy)
BlockPropertyImpl(NSString *, Order, orderBy)
BlockPropertyImpl(NSString *, Limit, limitIn)
BlockPropertyImpl(NSString *, Where, whereString)
BlockPropertyImpl(BOOL, Recursive, isRecursive)
BlockPropertyImpl(BOOL, NowInMain, isNowInMain)
BlockPropertyImpl(BOOL, Trasaction, useTransaction)
BlockPropertyImpl(BOOL, Desc, isDesc)
BlockPropertyImpl(JRDBChainComplete, Complete, completeBlock)


ArrrayPropertyImpl(Params, parameters)
ArrrayPropertyImpl(Columns, columnsArray)
ArrrayPropertyImpl(Ignore, ignoreArray)


@end
