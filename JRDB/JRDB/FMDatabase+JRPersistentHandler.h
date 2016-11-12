//
//  FMDatabase+JRPersistentBaseHandler.h
//  JRDB
//
//  Created by J on 2016/10/25.
//  Copyright © 2016年 Jrwong. All rights reserved.
//

#import <FMDB/FMDB.h>
#import "JRPersistentHandler.h"

@interface FMDatabase (JRPersistentHandler) <JRPersistentHandler>

@end

@interface FMDatabase (JRPersistentBaseHandler) <JRPersistentBaseHandler>

@end

@interface FMDatabase (JRPersistentOperationsHandler) <JRPersistentOperationsHandler>

@end

@interface FMDatabase (JRPersistentRecursiveOperationsHandler) <JRPersistentRecursiveOperationsHandler>

@end
