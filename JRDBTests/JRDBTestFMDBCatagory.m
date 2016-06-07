//
//  JRDBTestFMDBCatagory.m
//  JRDB
//
//  Created by JMacMini on 16/6/7.
//  Copyright © 2016年 Jrwong. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "JRDB.h"
#import "Person.h"

@interface JRDBTestFMDBCatagory : XCTestCase

@end

@implementation JRDBTestFMDBCatagory

- (void)setUp {
    [super setUp];
    [JRDBMgr defaultDB];
//    FMDatabase *db = [[JRDBMgr shareInstance] createDBWithPath:@"/Users/jmacmini/Desktop/test.sqlite"];
    [[JRDBMgr shareInstance] registerClazzes:@[
                                               [Person class],
                                               [Card class],
                                               [Money class],
                                               ]];
//    [JRDBMgr shareInstance].defaultDB = db;
    
    NSLog(@"%@", [[JRDBMgr shareInstance] registeredClazz]);
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [[JRDBMgr defaultDB] jr_closeQueue];
    [[JRDBMgr defaultDB] close];
    [super tearDown];
    
}

- (void)testSaveOne {
    Person *p = [self createPerson:1 name:@"1"];
    [p jr_save];
//    [p jr_saveWithComplete:^(BOOL success) {
//        NSLog(@"save complete");
//    }];
}


- (Person *)createPerson:(int)base name:(NSString *)name {
    Person *p = [[Person alloc] init];
    p.name = name;
    p.a_int = base + 1;
    p.b_unsigned_int = base + 2;
    p.c_long = base + 3;
    p.d_long_long = base + 4;
    p.e_unsigned_long = base + 5;
    p.f_unsigned_long_long = base + 6;
    p.g_float = base + 7.0;
    p.h_double = base + 8.0;
    p.i_string = [NSString stringWithFormat:@"%d", base + 9];
    p.j_number = @(10 + base);
    p.k_data = [NSData data];
    p.l_date = [NSDate date];
    p.m_date = [NSDate date];
    p.type = [NSString stringWithFormat:@"Person+%d", base];
    p.animal = [Animal new];
    
    return p;
}

- (Card *)createCard:(NSString *)serialNumber {
    Card *c = [Card new];
    c.serialNumber = serialNumber;
    return c;
}

@end
