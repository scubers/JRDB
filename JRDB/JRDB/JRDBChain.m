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
        _db = [JRDBMgr defaultDB];
        [self.Select([self class]).From(@"abc") execute:^(JRDBChain *chain, id result) {
            
        }];
    }
    return self;
}

- (id)execute:(JRDBChainComplete)complete {
    if (self.operation == CSelect) {
        return nil;
    } else if(self.isNowInMain) {
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

OperationBlockImpl(InsertBlock, Insert, CInsert)
OperationBlockImpl(UpdateBlock, Update, CUpdate)
OperationBlockImpl(DeleteBlock, Delete, CDelete)
OperationBlockImpl(DeleteAllBlock, DeleteAll, CDeleteAll)
OperationBlockImpl(SelectBlock, Select, CSelect)

BlockPropertyImpl(FMDatabase *, InDB, db)
BlockPropertyImpl(NSString *, From, tableName)

BlockPropertyImpl(NSString *, Group, groupBy)
BlockPropertyImpl(NSString *, Order, orderBy)
BlockPropertyImpl(NSString *, Limit, limitIn)

BlockPropertyImpl(NSArray *, Params, parameters)
BlockPropertyImpl(NSString *, Where, whereString)

BlockPropertyImpl(NSArray *, Columns, columnsArray)
BlockPropertyImpl(NSArray *, Ignore, ignoreArray)

BlockPropertyImpl(BOOL, Recursive, isRecursive)
BlockPropertyImpl(BOOL, NowInMain, isNowInMain)
BlockPropertyImpl(BOOL, Trasaction, useTransaction)
BlockPropertyImpl(BOOL, Desc, isDesc)
BlockPropertyImpl(JRDBChainComplete, Complete, completeBlock)


@end
