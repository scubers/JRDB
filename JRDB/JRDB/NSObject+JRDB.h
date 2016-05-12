//
//  NSObject+JRDB.h
//  JRDB
//
//  Created by JMacMini on 16/5/10.
//  Copyright © 2016年 Jrwong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JRPersistent.h"

@interface NSObject (JRDB) <JRPersistent>

+ (NSArray *)jr_excludePropertyNames;


@end