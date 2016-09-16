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
#import "JRDBChain.h"
#import <objc/runtime.h>


//#define Chain 1

@interface JRDBTests : XCTestCase

@end

@implementation JRDBTests

- (void)setUp {
    [super setUp];
    [JRDBMgr defaultDB];
    FMDatabase *db = [[JRDBMgr shareInstance] createDBWithPath:@"/Users/Jrwong/Desktop/test.sqlite"];
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
    
    [[JRDBMgr defaultDB] close];
    [super tearDown];
    
}

#pragma mark - test delete
- (void)testDeleteAll1 {
#ifndef Chain
    [Person jr_deleteAllOnly];
#else
    [[JRDBChain new].DeleteAll([Person class]).Recursive(NO) exe:^(JRDBChain *chain, id result) {
        NSLog(@"%@", result);
    }];
    
    
#endif
}

- (void)testDeleteAll {
#ifndef Chain
    [[Person jr_findAll] jr_delete];
    [[Card jr_findAll] jr_delete];
    [[Money jr_findAll] jr_delete];
#else
    [[JRDBChain new].DeleteAll([Person class]) exe:nil];
    [[JRDBChain new].DeleteAll([Card class]) exe:nil];
    [[JRDBChain new].DeleteAll([Money class]) exe:nil];
#endif
}

- (void)testDeleteOne {
#ifndef Chain
    Person *p = [Person jr_findAll].firstObject;
    [p jr_delete];
#else
    Person *p = [[J_Select([Person class]) exe:nil] firstObject];
    [J_Delete(p).Recursive(NO) exe:nil];
#endif

}

#pragma mark - test save
- (void)testSaveOne {
    Person *p = [self createPerson:1 name:@"1"];
#ifndef Chain
    [p jr_save];
#else
    [J_Insert(p) exe:nil];
#endif

}

- (void)testSaveMany {
    
    NSMutableArray *array = [NSMutableArray array];
    for (int i = 0; i < 10; i++) {
        [array addObject:[self createPerson:i name:[NSString stringWithFormat:@"%d", i]]];
    }
#ifndef Chain
//    [array jr_save];
    [array jr_save];
#else
    [J_Insert(array) exe:nil];
#endif

}

- (void)testSaveCycle {
    Person *p = [self createPerson:1 name:nil];
    Card *c = [self createCard:@"111"];
    p.card = c;
    c.person = p;
#ifndef Chain
    [p jr_save];
#else
    [J_Insert(p).Recursive(YES) exe:nil];
#endif
    
}

- (void)test3CycleSave {
    Person *p = [self createPerson:1 name:nil];
    Person *p1 = [self createPerson:2 name:nil];
    Person *p2 = [self createPerson:3 name:nil];
    p.son = p1;
    p1.son = p2;
    p2.son = p;
#ifndef Chain
    [p jr_save];
#else
    [J_Insert(p).Recursive(YES) exe:nil];
#endif
}

- (void)testOneToManySave {
    Person *p = [self createPerson:1 name:nil];
    for (int i = 0; i < 10; i++) {
        [p.money addObject:[self createMoney:i]];
    }
    [p.money addObjectsFromArray:[Money jr_findAll]];
    Person *p1 = [self createPerson:1 name:nil];
    for (int i = 0; i < 10; i++) {
        [p1.money addObject:[self createMoney:i]];
    }
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
#ifndef Chain
        [p1 jr_save];
#else
//        [J_INSERT(p).NowInMain(NO) exe:^(JRDBChain *chain, id result) {
//            NSLog(@"===");
//        }];
#endif
    });
#ifndef Chain
    [p jr_save];
#else
    
    [J_Insert(p).Recursive(YES) exe:nil];
#endif
    
}

- (void)testOneToManyChildren {
    Person *p = [self createPerson:0 name:nil];
    for (int i = 0; i < 10; i++) {
        [p.children addObject:[self createPerson:i + 1 name:nil]];
    }
//    p.money = [[Money jr_findAll] mutableCopy];
#ifndef Chain
    [p jr_save];
#else
//    [J_INSERT(p) exe:nil];
    [J_Insert(p).Recursive(YES) exe:nil];
#endif
}

#pragma mark - test update

- (void)testUpdateOne {
    Person *p = [Person jr_findAll].firstObject;
    p.a_int = 99999;
    p.b_unsigned_int = 9999;
    p.card = [self createCard:@"1121"];
    p.card.person = p;
    [p.money removeLastObject];
    
#ifndef Chain
//    [p jr_updateColumns:nil];
    [p jr_updateColumns:@[@"_a_int", @"_money"]];
#else
//    [[JRDBChain new].J_UPDATE(p) exe:nil];
//    NSLog(@"%@", [J_UPDATE(p).Columns(@[@"_a_int", @"_money"]) exe:nil]);
    NSLog(@"%@", [J_Update(p).Recursive(YES).Ignore(@"_money", nil) exe:nil]);
#endif
}

- (void)testUpdateMany {
    NSArray<Person *> * ps = [Person jr_findAll];
    [ps enumerateObjectsUsingBlock:^(Person * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.c_long = 4000;
        obj.a_int = 3000;
    }];
#ifndef Chain
    [ps jr_updateColumns:nil];
#else
    [J_Update(ps).Recursive(NO).Ignore(@"_c_long", nil) exe:nil];
#endif
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
    [[JRDBMgr defaultDB] jr_saveOrUpdateOne:p useTransaction:YES synchronized:YES complete:nil];
}

#pragma mark - test find 
- (void)testFindByCondition {
#ifndef Chain

#else
    NSArray<Person *> *ps = [J_Select([Person class])
                             .Where(@"_b_unsigned_int > ? or _c_long = ?")
                             .Params(@6, @3000, nil)
                             .Order(@"_ID")
                             .Desc(YES)
                             exe:nil];
#endif
    
}

- (void)testFindAll {
#ifndef Chain
    NSArray<Person *> *p = [Person jr_findAll];
    NSArray<Person *> *p1 = [Person jr_findAll];
#else
    NSArray<Person *> *p = [J_Select([Person class]) exe:nil];
    NSArray<Person *> *p1 = [J_Select([Person class]) exe:nil];
#endif
    
    [p isEqual:nil];
    [p1 isEqual:nil];
}

/**
 [J_SELECT([Person class]).From(@"table").Where(@"_age = ?").Params(@[@1]) exe:nil];
 [J_SELECT([Person class]).From(@"table").Where(@"_age = ?").Params(@[@1]) exe:nil];
 [J_SELECT(*).From(@"table").Where(@"_age = ?").Params(@[@1]) exe:nil];
 [J_SELECT(@[@"_age",@"_name"]).From(@"table").Where(@"_age = ?").Params(@[@1]) exe:nil];
 [J_SELECT([Person class]).count().From(@"table").Where(@"_age = ?").Params(@[@1]) exe:nil];
 */
- (void)testSelectChain {
    id re = [J_Select(Person).Desc(YES) exe:nil];
    NSLog(@"%@", re);
}

- (void)testAAA {
    Person *p = [Person jr_findAll].firstObject;
    p.a_int = 2;
    p.money = [[Money jr_findAll] mutableCopy];
    [J_Update(p).Recursive(YES) exe:nil];
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
//    p.bbbbb = base % 2;
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




