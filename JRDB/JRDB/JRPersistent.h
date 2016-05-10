//
//  JRPersistent.h
//  JRDB
//
//  Created by JMacMini on 16/5/10.
//  Copyright © 2016年 Jrwong. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol JRPersistent <NSObject>

@required
- (void)setID:(NSString *)ID;
- (NSString *)ID;

@optional
+ (NSArray *)jr_excludePropertyNames;

@end
