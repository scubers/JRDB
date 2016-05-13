//
//  JRDBTests.m
//  JRDBTests
//
//  Created by JMacMini on 16/5/10.
//  Copyright © 2016年 Jrwong. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "JRDB.h"
#import "Person.h"

//#import "Person.h"
//#import "JRReflectUtil.h"
//#import "NSObject+JRDB.h"
//#import "JRSqlGenerator.h"

@interface JRDBTests : XCTestCase

{
    FMDatabase *_db;
}

@end

@implementation JRDBTests

- (void)setUp {
    [super setUp];
//    _db = [JRDBMgr defaultDB];
    _db = [[JRDBMgr shareInstance] createDBWithPath:@"/Users/jmacmini/Desktop/test.sqlite"];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [_db close];
    [super tearDown];
    
}

- (void)testExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
}

- (void)testUpdate1 {
    NSArray *all = [_db findAll:[Person class]];
    
    Person *p = all.firstObject;
    
//    p.l_date = [NSDate date];
//    p.l_date = nil;

    [_db updateObj:p columns:nil];
    
}

- (void)testFind2 {
    NSArray *array = [_db findByConditions:@[
                                             [JRQueryCondition condition:@"_l_date < '2016-5-12 15:10'" type:JRQueryConditionTypeAnd],
                                             [JRQueryCondition condition:@"_a_int > 9" type:JRQueryConditionTypeAnd],
                                             ] clazz:[Person class] groupBy:@"_i_string" isDesc:YES];
    
    NSLog(@"%@", array);
}

- (void)testFind1 {
    NSArray *arr = [_db findAll:[Person class] orderBy:@"_a_int" isDesc:YES];
    
    Person *p = [_db getByID:[arr.firstObject ID] clazz:[Person class]];
    
    NSLog(@"%@, %@", arr, p);
}

- (void)testFindAll {
    NSArray *array = [_db findAll:[Person class]];
    Person *p = array.firstObject;
}

- (void)testAdd {
    
    for (int i = 0; i<1; i++) {
        Person *p = [[Person alloc] init];
        p.a_int = i+2;
        p.b_unsigned_int = 2;
        p.c_long = 3;
        p.d_long_long = 4;
        p.e_unsigned_long = 5;
        p.f_unsigned_long_long = 6;
        p.g_float = 7.0;
        p.h_double = 8.0;
        p.i_string = @"9";
        p.j_number = @10;
        p.k_data = [NSData data];
        p.l_date = [NSDate date];
        
        if ([_db saveObj:p]) {
            NSLog(@"success");
        }
        
    }
}

- (void)testTruncateTable {
    [_db truncateTable4Clazz:[Person class]];
    [[JRDBMgr defaultDB] truncateTable4Clazz:[Person class]];
}

- (void)testUpdateTable {
    [[JRDBMgr shareInstance] registerClazzForUpdateTable:[Person class]];
    [[JRDBMgr shareInstance] updateDefaultDB];
    
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
