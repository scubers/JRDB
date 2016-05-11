//
//  JRDBMgr.h
//  JRDB
//
//  Created by JMacMini on 16/5/10.
//  Copyright © 2016年 Jrwong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JRPersistent.h"

@class FMDatabase;

@interface JRDBMgr : NSObject

+ (instancetype)shareInstance;

- (FMDatabase *)createDBWithPath:(NSString *)path;
- (void)deleteDBWithPath:(NSString *)path;
- (FMDatabase *)DBWithPath:(NSString *)path;

//- (void)registerClazz:(Class<JRPersistent>)clazz;

@end
