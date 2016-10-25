//
//  JRQueueMgr.m
//  JRDB
//
//  Created by J on 2016/10/25.
//  Copyright © 2016年 Jrwong. All rights reserved.
//

#import "JRQueueMgr.h"

@interface JRQueueMgr ()

@property (nonatomic, strong) NSMutableDictionary<NSString *, NSOperationQueue *> *queues;

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

- (NSOperationQueue *)queueWithIdentifier:(NSString *)identifier {
    NSOperationQueue *queue = self.queues[identifier];
    if (!queue) {
        queue = [[NSOperationQueue alloc] init];
        self.queues[identifier] = queue;
    }
    return queue;
}

- (void)removeQueueWithIdentifier:(NSString *)identifier {
    [self.queues removeObjectForKey:identifier];
}

#pragma mark - getter setter

- (NSMutableDictionary<NSString *, NSOperationQueue *> *)queues {
    if (!_queues) {
        _queues = [[NSMutableDictionary<NSString *, NSOperationQueue *> alloc] init];
    }
    return _queues;
}
@end
