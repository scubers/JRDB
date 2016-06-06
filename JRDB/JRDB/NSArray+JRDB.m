//
//  NSArray+JRDB.m
//  JRDB
//
//  Created by JMacMini on 16/6/6.
//  Copyright © 2016年 Jrwong. All rights reserved.
//

#import "NSArray+JRDB.h"
#import "NSObject+JRDB.h"
#import "FMDatabase+JRDB.h"
#import "JRDBMgr.h"

@implementation NSArray (JRDB)

- (BOOL)jr_arraySaveUseTransaction:(BOOL)useTransaction toDB:(FMDatabase *)db {
    NSAssert([[JRDBMgr shareInstance] isValidateClazz:[[self firstObject] class]], @"class should be registered in JRDBMgr");
    if (useTransaction) {
        NSAssert(![db inTransaction], @"save error: database has been open an transaction");
        [db beginTransaction];
    }
    __block BOOL needRollBack = NO;
    [self enumerateObjectsUsingBlock:^(NSObject<JRPersistent> * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj jr_saveUseTransaction:NO];
    }];
    if (useTransaction) {
        if (needRollBack) {
            [db rollback];
        } else {
            [db commit];
        }
    }
    return !needRollBack;
}

- (void)jr_arraySaveUseTransaction:(BOOL)useTransaction toDB:(FMDatabase *)db complete:(JRDBComplete)complete {
    [db inQueue:^(FMDatabase * _Nonnull db) {
        EXE_BLOCK(complete, [self jr_arraySaveUseTransaction:useTransaction toDB:db]);
    }];
}

@end
