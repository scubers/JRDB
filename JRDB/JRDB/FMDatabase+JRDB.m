//
//  FMDatabase+JRDB.m
//  JRDB
//
//  Created by JMacMini on 16/5/10.
//  Copyright © 2016年 Jrwong. All rights reserved.
//



#import "FMDatabase+JRDB.h"
#import <objc/runtime.h>
#import "JRSqlGenerator.h"
static NSString *queuekey = @"queuekey";

NSString * uuid() {
    CFUUIDRef uuidObject = CFUUIDCreate(kCFAllocatorDefault);
    NSString *uuidStr = (NSString *)CFBridgingRelease(CFUUIDCreateString(kCFAllocatorDefault, uuidObject));
    CFRelease(uuidObject);
    return uuidStr;
}

@implementation FMDatabase (JRDB)

- (FMDatabaseQueue *)myQueue {
    FMDatabaseQueue *q = objc_getAssociatedObject(self, &queuekey);
    if (!q) {
        q = [FMDatabaseQueue databaseQueueWithPath:self.databasePath];
        objc_setAssociatedObject(self, &queuekey, q, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return q;
}

- (BOOL)saveObj:(id<JRPersistent>)obj {
    return [self saveObj:obj synchronized:NO];
}

- (BOOL)saveObj:(id<JRPersistent>)obj synchronized:(BOOL)synchronized {
    NSArray *args;
    NSString *sql = [JRSqlGenerator sql4Insert:obj args:&args];
    if (!obj.ID.length) {
        [obj setID:uuid()];
    }
    return [self executeUpdate:sql withArgumentsInArray:args];
}

@end
