//
//  FMDatabase+Chain.h
//  JRDB
//
//  Created by JMacMini on 16/7/11.
//  Copyright © 2016年 Jrwong. All rights reserved.
//

#import <FMDB/FMDB.h>
#import "JRPersistent.h"


@class JRDBChain;

@interface FMDatabase (Chain)

//- (BOOL)jr_executeUpdateChain:(JRDBChain *)chain;
- (BOOL)jr_executeUpdateChain:(JRDBChain *)chain;

- (id)jr_executeQueryChain:(JRDBChain *)chain;
- (id)jr_executeCustomizedQueryChain:(JRDBChain *)chain;




@end
