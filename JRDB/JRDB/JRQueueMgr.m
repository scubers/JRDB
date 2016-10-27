//
//  JRQueueMgr.m
//  JRDB
//
//  Created by J on 2016/10/25.
//  Copyright © 2016年 Jrwong. All rights reserved.
//

#import "JRQueueMgr.h"

static const void * const kJRQueueSpecificKey = &kJRQueueSpecificKey;

@interface JRQueueMgr ()

@property (nonatomic, strong) NSMutableDictionary<NSString *, dispatch_queue_t> *queues;

@end

@implementation JRQueueMgr

static JRQueueMgr *__instance;

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __instance = [super allocWithZone:zone];
    });
    return __instance;
}

+ (instancetype)shared {
    if (__instance) return __instance;
    return [[self alloc] init];
}

- (dispatch_queue_t)queueWithIdentifier:(NSString *)identifier {
    @synchronized (self) {
        dispatch_queue_t queue = self.queues[identifier];
        if (!queue) {
            queue = dispatch_queue_create(identifier.UTF8String, DISPATCH_QUEUE_SERIAL);
            dispatch_queue_set_specific(queue, kJRQueueSpecificKey, (__bridge void *)[NSObject new], NULL);
            self.queues[identifier] = queue;
        }
        return queue;
    }
}

- (void)removeQueueWithIdentifier:(NSString *)identifier {
    [self.queues removeObjectForKey:identifier];
}

- (BOOL)isInCurrentQueue:(NSString *)identifier {
    return dispatch_get_specific(kJRQueueSpecificKey) != NULL;
}

#pragma mark - getter setter


- (NSMutableDictionary<NSString *, dispatch_queue_t> *)queues {
    if (!_queues) {
        _queues = [[NSMutableDictionary<NSString *, dispatch_queue_t> alloc] init];
    }
    return _queues;
}
@end
