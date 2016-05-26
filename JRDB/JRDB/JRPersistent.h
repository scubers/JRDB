//
//  JRPersistent.h
//  JRDB
//
//  Created by JMacMini on 16/5/10.
//  Copyright © 2016年 Jrwong. All rights reserved.
//

#import <Foundation/Foundation.h>

#define EXE_BLOCK(block, ...) if (block){block(__VA_ARGS__);}

typedef void(^JRDBComplete)(BOOL success);

@protocol JRPersistent <NSObject>

@required
- (void)setID:(NSString * _Nullable)ID;
- (NSString * _Nullable)ID;

@optional
/**
 *  返回不用入库的对象字段数组
 *  The full property names that you want to ignore for persistent
 *
 *  @return array
 */
+ (NSArray * _Nullable)jr_excludePropertyNames;

/**
 *  返回自定义主键字段
 *
 *  @return 字段全名
 */
+ (NSString * _Nullable)jr_customPrimarykey;

/**
 *  返回自定义主键值
 *
 *  @return 主键值
 */
- (id _Nullable)jr_customPrimarykeyValue;


@end
