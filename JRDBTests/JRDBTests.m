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

@end

@implementation JRDBTests

- (void)setUp {
    [super setUp];
    [[JRDBMgr shareInstance] registerClazzForUpdateTable:[Person class]];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [[JRDBMgr defaultDB] close];
    [super tearDown];
    
}

- (void)testExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
}

- (void)testUpdate {
    Person *p = [Person new];
    p.a_int = 11;
    [p jr_updateWithColumn:nil];
//    NSArray *all = [Person jr_findAll];
//    
//    Person *p = all.firstObject;
//
//    p.a_int = 100;
//
//    [p jr_updateWithColumn:nil];
    
}

- (void)testSql {
    Person *person;
    [[JRDBMgr defaultDB] createTable4Clazz:[Person class]];
    [Person jr_createTable];
    
    [[JRDBMgr defaultDB] truncateTable4Clazz:[Person class]];
    [Person jr_truncateTable];
    
    [person jr_save];
    
    [[JRDBMgr defaultDB] updateTable4Clazz:[Person class]];
    [Person jr_updateTable];
    
    [[JRDBMgr defaultDB] dropTable4Clazz:[Person class]];
    [Person jr_dropTable];
    
}

- (void)testDelete {
    Person *p = [Person new];
    p.a_int = 11;
    [p jr_delete];
}

- (void)testFind2 {
    
    NSArray *condis = @[
                        [JRQueryCondition type:JRQueryConditionTypeAnd condition:@"_a_int > ? and _l_date < ?", @9, [NSDate date], nil],
                        ];
    
    NSArray *arr = [Person jr_findByConditions:condis
                                       groupBy:nil
                                       orderBy:nil
                                         limit:nil
                                        isDesc:YES];
    
    NSLog(@"%@", arr);
    
    [[JRDBMgr defaultDB] close];
}

- (void)testFind1 {
    
    NSArray *arr = [Person jr_findAllOrderBy:@"_a_int" isDesc:YES];
    
//    Person *p = [Person jr_findByPrimaryKey:[arr.firstObject ID]];
    Person *p = [Person jr_findByPrimaryKey:@([arr.firstObject a_int])];
    
    NSLog(@"%@, %@, %@", arr, p, p.j_number);
}

- (void)testFindAll {
    NSArray<Person *> *array = [Person jr_findAll];
    NSLog(@"%@", array);
    [array enumerateObjectsUsingBlock:^(Person * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSLog(@"%@", obj.jr_changedArray);
        obj.a_int = 11;
        NSLog(@"%@", obj.jr_changedArray);

    }];
}

- (void)testCustomPK {
    
}

- (void)testAdd {
//    Person *p = [Person new];
//    [p setValue:@"abc" forKey:@"_type"];
    for (int i = 0; i<1; i++) {
        Person *p = [[Person alloc] init];
        p.a_int = i;
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
        p.m_date = [NSDate date];
        p.type = @"Person";
        p.animal = [Animal new];
        NSLog(@"%@", p.jr_changedArray);
        [p jr_save];
        NSLog(@"%@", p.jr_changedArray);
    }
}

- (void)testTruncateTable {
    [Person jr_dropTable];
//    [Person jr_truncateTable];
//    [_db truncateTable4Clazz:[Person class]];
//    [[JRDBMgr defaultDB] truncateTable4Clazz:[Person class]];
    
}

- (void)testUpdateTable {
    [[JRDBMgr shareInstance] registerClazzForUpdateTable:[Person class]];
    Person *p = [Person new];
    p.a_int = 1;
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
    p.type = @"Person";

    NSLog(@"%@", p.jr_changedArray);
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
        Person *p = [Person new];
        [p jr_save];
    }];
}

- (void)testIvars {
    NSDictionary *dict = [JRReflectUtil ivarAndEncode4Clazz:[Person class]];
    NSLog(@"%@", dict);
}

@end
