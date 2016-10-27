//
//  JRQueueMgr.h
//  JRDB
//
//  Created by J on 2016/10/25.
//  Copyright © 2016年 Jrwong. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JRQueueMgr : NSObject

+ (instancetype)shared;

- (dispatch_queue_t)queueWithIdentifier:(NSString *)identifier;

- (void)removeQueueWithIdentifier:(NSString *)identifier;

- (BOOL)isInCurrentQueue:(NSString *)identifier;

@end
