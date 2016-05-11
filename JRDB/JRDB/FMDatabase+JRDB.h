//
//  FMDatabase+JRDB.h
//  JRDB
//
//  Created by JMacMini on 16/5/10.
//  Copyright © 2016年 Jrwong. All rights reserved.
//

#import <FMDB/FMDB.h>
#import "JRPersistent.h"

@interface FMDatabase (JRDB)

- (void)createTable4Clazz:(Class<JRPersistent>)clazz;
- (void)updateTable4Clazz:(Class<JRPersistent>)clazz;
- (void)deleteTable4Clazz:(Class<JRPersistent>)clazz;


- (BOOL)saveObj:(id<JRPersistent>)obj;
- (BOOL)saveObj:(id<JRPersistent>)obj synchronized:(BOOL)synchronized;
- (BOOL)deleteObj:(id<JRPersistent>)obj;
- (BOOL)deleteObj:(id<JRPersistent>)obj synchronized:(BOOL)synchronized;

- (BOOL)updateObj:(id<JRPersistent>)obj;
- (BOOL)updateObj:(id<JRPersistent>)obj columns:(NSArray *)columns;
- (BOOL)updateObj:(id<JRPersistent>)obj columns:(NSArray *)columns synchronized:(BOOL)synchronized;;

- (id<JRPersistent>)getByID:(NSString *)ID clazz:(Class<JRPersistent>)clazz;
- (id<JRPersistent>)getByID:(NSString *)ID clazz:(Class<JRPersistent>)clazz synchronized:(BOOL)synchronized;;

- (NSArray *)findAll:(Class<JRPersistent>)clazz;
- (NSArray *)findAll:(Class<JRPersistent>)clazz synchronized:(BOOL)synchronized;;

@end
