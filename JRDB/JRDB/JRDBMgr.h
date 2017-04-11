//
//  JRDBMgr.h
//  JRDB
//
//  Created by JMacMini on 16/5/10.
//  Copyright © 2016年 Jrwong. All rights reserved.
//

#import "JRPersistent.h"
#import "JRPersistentHandler.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface JRDBMgr : NSObject

@property (nonatomic, strong, nullable) NSString *defaultDatabasePath;///< default database path

@property (nonatomic, assign) int maxConnectionCount;///< connetion count, 1 by default

@property (nonatomic, assign) BOOL debugMode;///< print sql if YES;

+ (instancetype)shareInstance;

#pragma mark - database operation

/** get a default database handler from the connection pool */
- (id<JRPersistentHandler>)getHandler;
/** get a sepecific database handler from the connection pool */
- (id<JRPersistentHandler>)getHandlerWithPath:(NSString *)path;

/** physicaly delete the database */
- (void)deleteDatabaseWithPath:(NSString * _Nullable)path;

#pragma mark - logic operation

/** register classes, you can only use the class that registered here */
- (void)registerClazz:(Class<JRPersistent>)clazz;
- (void)registerClazzes:(NSArray<Class<JRPersistent>> *)clazzArray;

- (NSArray<Class<JRPersistent>> *)registeredClazz;

/** close the database, you should call this when app exit */
- (void)close;
- (void)closeDatabaseWithPath:(NSString *)path;

@end


NS_ASSUME_NONNULL_END
