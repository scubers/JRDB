//
//  JRUtils.m
//  JRDB
//
//  Created by 王俊仁 on 16/6/3.
//  Copyright © 2016年 Jrwong. All rights reserved.
//

#import "JRUtils.h"

@implementation JRUtils

+ (NSString *)uuid {
    CFUUIDRef uuidObject = CFUUIDCreate(kCFAllocatorDefault);
    NSString *uuidStr = (NSString *)CFBridgingRelease(CFUUIDCreateString(kCFAllocatorDefault, uuidObject));
    CFRelease(uuidObject);
    return uuidStr;
}



@end
