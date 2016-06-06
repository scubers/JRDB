//
//  NSArray+JRDB.h
//  JRDB
//
//  Created by JMacMini on 16/6/6.
//  Copyright © 2016年 Jrwong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JRPersistent.h"

@class FMDatabase;

@interface NSArray (JRDB)

- (BOOL)jr_arraySaveUseTransaction:(BOOL)useTransaction toDB:(FMDatabase * _Nonnull)db;
- (void)jr_arraySaveUseTransaction:(BOOL)useTransaction toDB:(FMDatabase * _Nonnull)db complete:(JRDBComplete _Nullable)complete;

- (BOOL)jr_arrayUpdateColumn:(NSArray<NSString *> * _Nullable)column useTransaction:(BOOL)useTransaction toDB:(FMDatabase * _Nonnull)db;
- (void)jr_arrayUpdateColumn:(NSArray<NSString *> * _Nullable)column useTransaction:(BOOL)useTransaction toDB:(FMDatabase * _Nonnull)db complete:(JRDBComplete _Nullable)complete;


@end
