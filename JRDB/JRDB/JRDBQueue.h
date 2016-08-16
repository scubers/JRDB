//
//  JRDBQueue.h
//  JRDB
//
//  Created by JMacMini on 16/7/15.
//  Copyright © 2016年 Jrwong. All rights reserved.
//

#import <FMDB/FMDB.h>

static const void * const kJRDBQueueSpecificKey = &kJRDBQueueSpecificKey;

@interface JRDBQueue : FMDatabaseQueue

- (BOOL)isInCurrentQueue;

@end
