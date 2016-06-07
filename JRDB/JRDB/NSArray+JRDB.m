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

#pragma mark - save
- (BOOL)jr_saveUseTransaction:(BOOL)useTransaction toDB:(FMDatabase *)db {
    return [db jr_saveObjects:self useTransaction:useTransaction];
}

- (void)jr_saveUseTransaction:(BOOL)useTransaction complete:(JRDBComplete)complete toDB:(FMDatabase *)db {
    return [db jr_saveObjects:self useTransaction:useTransaction complete:complete];
}

- (BOOL)jr_saveToDB:(FMDatabase *)db {
    return [db jr_saveObjects:self];
}

- (void)jr_saveWithComplete:(JRDBComplete)complete toDB:(FMDatabase *)db {
    return [db jr_saveObjects:self complete:complete];
}

#pragma mark - save use DefaultDB

- (BOOL)jr_saveUseTransaction:(BOOL)useTransaction {
    return [self jr_saveUseTransaction:useTransaction toDB:JR_DEFAULTDB];
}

- (void)jr_saveUseTransaction:(BOOL)useTransaction complete:(JRDBComplete)complete {
    [self jr_saveUseTransaction:useTransaction complete:complete toDB:JR_DEFAULTDB];
}

- (BOOL)jr_save {
    return [self jr_saveToDB:JR_DEFAULTDB];
}

- (void)jr_saveWithComplete:(JRDBComplete)complete {
    return [self jr_saveWithComplete:complete toDB:JR_DEFAULTDB];
}

#pragma mark - update

- (BOOL)jr_updateColumns:(NSArray<NSString *> *)columns useTransaction:(BOOL)useTransaction toDB:(FMDatabase *)db {
    return [db jr_updateObjects:self columns:columns useTransaction:useTransaction];
}

- (void)jr_updateColumns:(NSArray<NSString *> *)columns useTransaction:(BOOL)useTransaction complete:(JRDBComplete)complete toDB:(FMDatabase *)db {
    return [db jr_updateObjects:self columns:columns useTransaction:useTransaction complete:complete];
}

- (BOOL)jr_updateColumns:(NSArray<NSString *> *)columns toDB:(FMDatabase *)db {
    return [db jr_updateObjects:self columns:columns useTransaction:YES];
}

- (void)jr_updateColumns:(NSArray<NSString *> *)columns complete:(JRDBComplete)complete toDB:(FMDatabase *)db {
    [db jr_updateObjects:self columns:columns complete:complete];
}

#pragma mark - update use DefaultDB

- (BOOL)jr_updateColumns:(NSArray<NSString *> *)columns useTransaction:(BOOL)useTransaction {
    return [self jr_updateColumns:self useTransaction:useTransaction toDB:JR_DEFAULTDB];
}

- (void)jr_updateColumns:(NSArray<NSString *> *)columns useTransaction:(BOOL)useTransaction complete:(JRDBComplete)complete {
    return [self jr_updateColumns:columns useTransaction:useTransaction complete:complete toDB:JR_DEFAULTDB];
}

- (BOOL)jr_updateColumns:(NSArray<NSString *> *)columns {
    return [self jr_updateColumns:columns toDB:JR_DEFAULTDB];
}

- (void)jr_updateColumns:(NSArray<NSString *> *)columns complete:(JRDBComplete)complete {
    return [self jr_updateColumns:columns complete:complete toDB:JR_DEFAULTDB];
}

#pragma mark - delete

- (BOOL)jr_deleteUseTransaction:(BOOL)useTransaction fromDB:(FMDatabase *)db {
    return [db jr_deleteObjects:self useTransaction:useTransaction];
}

- (void)jr_deleteUseTransaction:(BOOL)useTransaction complete:(JRDBComplete)complete fromDB:(FMDatabase *)db {
    [db jr_deleteObjects:self useTransaction:useTransaction complete:complete];
}

- (BOOL)jr_deleteFromDB:(FMDatabase *)db {
    return [db jr_deleteObjects:self];
}

- (void)jr_deleteWithComplete:(JRDBComplete)complete fromDB:(FMDatabase *)db {
    [db jr_deleteObjects:self complete:complete];
}

#pragma mark - delete use DefaultDB

- (BOOL)jr_deleteUseTransaction:(BOOL)useTransaction {
    return [self jr_deleteUseTransaction:useTransaction fromDB:JR_DEFAULTDB];
}

- (void)jr_deleteUseTransaction:(BOOL)useTransaction complete:(JRDBComplete)complete {
    return [self jr_deleteUseTransaction:useTransaction complete:complete fromDB:JR_DEFAULTDB];
}

- (BOOL)jr_delete {
    return [self jr_deleteFromDB:JR_DEFAULTDB];
}

- (void)jr_deleteWithComplete:(JRDBComplete)complete {
    return [self jr_deleteWithComplete:complete fromDB:JR_DEFAULTDB];
}

@end
