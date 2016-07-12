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
#import "NSObject+Reflect.h"


//#import "Person.h"
//#import "JRReflectUtil.h"
//#import "NSObject+JRDB.h"
//#import "JRSqlGenerator.h"


@interface JRDBTests : XCTestCase

@end

@implementation JRDBTests

- (void)setUp {
    [super setUp];
    [JRDBMgr defaultDB];
    FMDatabase *db = [[JRDBMgr shareInstance] createDBWithPath:@"/Users/jmacmini/Desktop/test.sqlite"];
    [[JRDBMgr shareInstance] registerClazzes:@[
                                               [Person class],
                                               [Card class],
                                               [Money class],
                                               ]];
    [JRDBMgr shareInstance].defaultDB = db;
    
//    [JRDBMgr shareInstance].debugMode = NO;
    
    NSLog(@"%@", [[JRDBMgr shareInstance] registeredClazz]);
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [[JRDBMgr defaultDB] jr_closeQueue];
    [[JRDBMgr defaultDB] close];
    [super tearDown];
    
}

#pragma mark - test delete
- (void)testDeleteAll1 {
    [Person jr_deleteAllOnly];
}

- (void)testDeleteAll {
    [[Person jr_findAll] jr_delete];
    [[Card jr_findAll] jr_delete];
    [[Money jr_findAll] jr_delete];
}

- (void)testDeleteOne {
    Person *p = [Person jr_findAll].firstObject;
    [p jr_delete];
}

#pragma mark - test save
- (void)testSaveOne {
    Person *p = [self createPerson:1 name:@"1"];
    [p jr_save];
}

- (void)testSaveMany {
    
    NSMutableArray *array = [NSMutableArray array];
    for (int i = 0; i < 10; i++) {
        [array addObject:[self createPerson:i name:[NSString stringWithFormat:@"%d", i]]];
    }
//    [array jr_save];
    [Person jr_findAll];
    [array jr_saveWithComplete:^(BOOL success) {
        NSLog(@"success");
    }];
}

- (void)testSaveCycle {
    Person *p = [self createPerson:1 name:nil];
    Card *c = [self createCard:@"111"];
    p.card = c;
    c.person = p;
    
    [[JRDBMgr defaultDB] jr_saveOne:p recursave:NO useTransaction:YES];
    
}

- (void)test3CycleSave {
    Person *p = [self createPerson:1 name:nil];
    Person *p1 = [self createPerson:2 name:nil];
    Person *p2 = [self createPerson:3 name:nil];
    p.son = p1;
    p1.son = p2;
    p2.son = p;
    [p jr_save];
}

- (void)testOneToManySave {
    Person *p = [self createPerson:1 name:nil];
    for (int i = 0; i < 10; i++) {
        [p.money addObject:[self createMoney:i]];
    }
    Person *p1 = [self createPerson:1 name:nil];
    for (int i = 0; i < 10; i++) {
        [p1.money addObject:[self createMoney:i]];
    }
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [p1 jr_saveWithComplete:^(BOOL success) {
            NSLog(@"===");
        }];
    });
    [p jr_save];
    
}

- (void)testOneToManyChildren {
    Person *p = [self createPerson:0 name:nil];
    for (int i = 0; i < 10; i++) {
        [p.children addObject:[self createPerson:i + 1 name:nil]];
    }
    [p jr_save];
}

#pragma mark - test update

- (void)testUpdateOne {
    Person *p = [Person jr_findAll].firstObject;
    p.a_int = 9999;
    p.b_unsigned_int = 9999;
//    p.money = [[p.money subarrayWithRange:NSMakeRange(0, 3)] mutableCopy];
//    [p jr_updateColumns:nil];
    [p jr_updateColumns:@[@"_a_int", @"_money"]];
}

- (void)testUpdateMany {
    NSArray<Person *> * ps = [Person jr_findAll];
    [ps enumerateObjectsUsingBlock:^(Person * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.c_long = 3000;
    }];
    [ps jr_updateColumns:nil];
}

#pragma mark - test saveOrUpdate
- (void)testSaveOrUpdateObjects {
    NSArray<Person *> *ps = [Person jr_findAll];
    NSMutableArray *array = [NSMutableArray array];
    for (int i = 100; i < 110; i++) {
        [array addObject:[self createPerson:i name:nil]];
    }
    [array addObjectsFromArray:ps];
    [array jr_saveOrUpdate];
}

- (void)testSaveOrUpdateOne {
    Person *p = [self createPerson:100 name:nil];
    [[JRDBMgr defaultDB] jr_saveOrUpdateOne:p useTransaction:YES];
}

#pragma mark - test find 
- (void)testFindByCondition {
    NSArray<Person *> *ps =[Person jr_findByConditions:@[
                                     [JRQueryCondition condition:@"_b_unsigned_int > ?" args:@[@6] type:JRQueryConditionTypeAnd],
                                     [JRQueryCondition condition:@"_c_long = ?" args:@[@3000] type:JRQueryConditionTypeOr],
                                     ]
                                               groupBy:nil
                                               orderBy:@"_ID"
                                                 limit:nil
                                                isDesc:YES];
    
    NSLog(@"%@", ps);
}

- (void)testFindAll {
    NSArray<Person *> *p = [Person jr_findAll];
    NSArray<Person *> *p1 = [Person jr_findAll];
    [p isEqual:nil];
    [p1 isEqual:nil];
}

#pragma mark - convenience method
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
    p.bbbbb = base % 2;
    return p;
}

- (Card *)createCard:(NSString *)serialNumber {
    Card *c = [Card new];
    c.serialNumber = serialNumber;
    return c;
}

- (Money *)createMoney:(int)value {
    Money *m = [Money new];
    m.value = [NSString stringWithFormat:@"%d", value];
    return m;
}

@end




