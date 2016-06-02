//
//  JRTableSchema.h
//  JRDB
//
//  Created by JMacMini on 16/6/2.
//  Copyright © 2016年 Jrwong. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JRColumnSchema : NSObject
//get table schema: result colums: cid[INTEGER], name,type [STRING], notnull[INTEGER], dflt_value[],pk[INTEGER]

@property (nonatomic, assign) NSInteger cid;
@property (nonatomic, copy  ) NSString  *name;
@property (nonatomic, copy  ) NSString  *type;
@property (nonatomic, assign) BOOL      notnull;
@property (nonatomic, assign) NSInteger pk;


@end
