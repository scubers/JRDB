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


#pragma mark - save or update

- (BOOL)jr_saveOrUpdateUseTransaction:(BOOL)useTransaction toDB:(FMDatabase * _Nonnull)db {
    return [db jr_saveOrUpdateObjects:self useTransaction:useTransaction synchronized:YES complete:nil];
}
- (void)jr_saveOrUpdateUseTransaction:(BOOL)useTransaction complete:(JRDBComplete _Nullable)complete  toDB:(FMDatabase * _Nonnull)db {
    [db jr_saveOrUpdateObjects:self useTransaction:useTransaction synchronized:YES complete:complete];
}

- (BOOL)jr_saveOrUpdateToDB:(FMDatabase * _Nonnull)db {
    return [db jr_saveOrUpdateObjects:self useTransaction:YES synchronized:YES complete:nil];
}
- (void)jr_saveOrUpdateWithComplete:(JRDBComplete _Nullable)complete toDB:(FMDatabase * _Nonnull)db {
    [db jr_saveOrUpdateObjects:self useTransaction:YES synchronized:YES complete:complete];
}

#pragma mark - save or update use DefaultDB

- (BOOL)jr_saveOrUpdateUseTransaction:(BOOL)useTransaction {
    return [self jr_saveOrUpdateUseTransaction:useTransaction toDB:JR_DEFAULTDB];
}
- (void)jr_saveOrUpdateUseTransaction:(BOOL)useTransaction complete:(JRDBComplete _Nullable)complete {
    [self jr_saveOrUpdateUseTransaction:useTransaction complete:complete toDB:JR_DEFAULTDB];
}

- (BOOL)jr_saveOrUpdate {
    return [self jr_saveOrUpdateUseTransaction:YES toDB:JR_DEFAULTDB];
}
- (void)jr_saveOrUpdateWithComplete:(JRDBComplete _Nullable)complete {
    [self jr_saveOrUpdateUseTransaction:YES complete:complete toDB:JR_DEFAULTDB];
}

#pragma mark - save
- (BOOL)jr_saveUseTransaction:(BOOL)useTransaction toDB:(FMDatabase *)db {
    return [db jr_saveObjects:self useTransaction:useTransaction synchronized:YES complete:nil];
}

- (void)jr_saveUseTransaction:(BOOL)useTransaction complete:(JRDBComplete)complete toDB:(FMDatabase *)db {
    [db jr_saveObjects:self useTransaction:useTransaction synchronized:YES complete:complete];
}

- (BOOL)jr_saveToDB:(FMDatabase *)db {
    return [db jr_saveObjects:self useTransaction:YES synchronized:YES complete:nil];
}

- (void)jr_saveWithComplete:(JRDBComplete)complete toDB:(FMDatabase *)db {
    [db jr_saveObjects:self useTransaction:YES synchronized:YES complete:complete];
}

#pragma mark - update

- (BOOL)jr_updateColumns:(NSArray<NSString *> *)columns useTransaction:(BOOL)useTransaction toDB:(FMDatabase *)db {
    return [db jr_updateObjects:self columns:columns useTransaction:useTransaction synchronized:YES complete:nil];
}

- (void)jr_updateColumns:(NSArray<NSString *> *)columns useTransaction:(BOOL)useTransaction complete:(JRDBComplete)complete toDB:(FMDatabase *)db {
    [db jr_updateObjects:self columns:columns useTransaction:useTransaction synchronized:YES complete:complete];
}

- (BOOL)jr_updateColumns:(NSArray<NSString *> *)columns toDB:(FMDatabase *)db {
    return [db jr_updateObjects:self columns:columns useTransaction:YES synchronized:YES complete:nil];
}

- (void)jr_updateColumns:(NSArray<NSString *> *)columns complete:(JRDBComplete)complete toDB:(FMDatabase *)db {
    [db jr_updateObjects:self columns:columns useTransaction:YES synchronized:YES complete:complete];
}

#pragma mark - delete

- (BOOL)jr_deleteUseTransaction:(BOOL)useTransaction fromDB:(FMDatabase *)db {
    return [db jr_deleteObjects:self useTransaction:useTransaction synchronized:YES complete:nil];
}

- (void)jr_deleteUseTransaction:(BOOL)useTransaction complete:(JRDBComplete)complete fromDB:(FMDatabase *)db {
    [db jr_deleteObjects:self useTransaction:useTransaction synchronized:YES complete:complete];
}

- (BOOL)jr_deleteFromDB:(FMDatabase *)db {
    return [db jr_deleteObjects:self useTransaction:YES synchronized:YES complete:nil];
}

- (void)jr_deleteWithComplete:(JRDBComplete)complete fromDB:(FMDatabase *)db {
    [db jr_deleteObjects:self useTransaction:YES synchronized:YES complete:complete];
}

@end
