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
#import "JRColumnSchema.h"


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

- (void)testAdd {
    //    Person *p = [Person new];
    //    [p setValue:@"abc" forKey:@"_type"];
    for (int i = 0; i<10; i++) {
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
        [p jr_save];
    }
}

- (void)testUpdate {
}


- (void)testDelete {
    Person *p = [Person new];
    p.a_int = 11;
    [p jr_delete];
}


- (void)testFindAll {
    NSArray *array = [Person jr_findAll];
    NSLog(@"%@", array);
    [array enumerateObjectsUsingBlock:^(Person * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSLog(@"%@", obj.jr_changedArray);
        obj.a_int = 11;
        NSLog(@"%@", obj.jr_changedArray);

    }];
}
//alter table tablename rename column oldColumnName to newColumnName;

- (void)testTruncateTable {
    [[JRDBMgr shareInstance] deleteDBWithPath:[JRDBMgr defaultDB].databasePath];
    
}

- (void)testUpdateTable {
    [[JRDBMgr shareInstance] registerClazzForUpdateTable:[Person class]];
    [Person jr_updateTable];
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
        Person *p = [Person new];
        [p jr_save];
    }];
}


- (void)testSql11 {
    Person *p = [self createPerson:1];
    Card *c = [self createCard:@"001"];
    p.card = c;
    c.person = p;
    [p jr_save];
}



- (void)testSomething {
    NSArray *array = [Person jr_findAll];
    NSArray *arr = [Card jr_findAll];
    [array isEqual:nil];
    [arr isEqual:nil];
    
}

- (Person *)createPerson:(int)base {
    Person *p = [[Person alloc] init];
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




