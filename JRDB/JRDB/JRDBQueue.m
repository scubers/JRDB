//
//  JRDBQueue.m
//  JRDB
//
//  Created by JMacMini on 16/7/15.
//  Copyright © 2016年 Jrwong. All rights reserved.
//

#import "JRDBQueue.h"

@implementation JRDBQueue

- (instancetype)initWithPath:(NSString *)aPath flags:(int)openFlags vfs:(NSString *)vfsName {
    if (self = [super initWithPath:aPath flags:openFlags vfs:vfsName]) {
        dispatch_queue_set_specific(self->_queue, kJRDBQueueSpecificKey, (__bridge void *)self, NULL);
    }
    return self;
}

- (BOOL)isInCurrentQueue {
    return dispatch_get_specific(kJRDBQueueSpecificKey) == (__bridge void *)self;
}

@end
