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
    FMDatabase *db = [[JRDBMgr shareInstance] createDBWithPath:@"/Users/Jrwong/Desktop/test.sqlite"];
    [[JRDBMgr shareInstance] registerClazzForUpdateTable:[Person class]];
    [JRDBMgr shareInstance].defaultDB = db;
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
    Person *p = (Person *)[Person jr_findAll].firstObject;
    p.card.person = p;
    [p.card jr_updateWithColumn:nil];
//    [p jr_updateWithColumn:nil];
//    [p isEqual:nil];
    
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
    Person *p = [self createPerson:1 name:@"A"];
    Card *c = [self createCard:@"001"];
    Card *c1 = [self createCard:@"002"];
    p.card = c;
    p.card1 = c1;
    c.person = p;
    c1.person = p;

    [p jr_addDidFinishBlock:^(id<JRPersistent>  _Nonnull obj) {
        NSLog(@"finish save %@", obj);
    } forIdentifier:@"abc"];

    [p jr_save];
    
    NSLog(@"------");
}

- (void)test2Cycle {
    Person *father = [self createPerson:1 name:@"A"];
    Person *son = [self createPerson:2  name:@"B"];
    father.son = son;
    
    Card *c = [self createCard:@"001"];
    son.card = c;
    c.person = son;

//    [father jr_save];
    [father jr_saveUseTransaction:NO];


}

- (void)test3Node {
    Person *father = [self createPerson:1 name:@"A"];
    Person *son = [self createPerson:2 name:@"B"];
    Person *subSon = [self createPerson:3 name:@"C"];
    
    father.son = son;
    son.son = subSon;
    subSon.son = father;
    
    [father jr_addDidFinishBlock:^(id<JRPersistent>  _Nonnull obj) {
        NSLog(@"father saved");
    } forIdentifier:@"1"];
    [son jr_addDidFinishBlock:^(id<JRPersistent>  _Nonnull obj) {
        NSLog(@"son saved");
    } forIdentifier:@"1"];
    [subSon jr_addDidFinishBlock:^(id<JRPersistent>  _Nonnull obj) {
        NSLog(@"subson saved");
    } forIdentifier:@"1"];
    
    [father jr_save];
}

- (void)testTransaction {
    [[JRDBMgr defaultDB] inTransaction:^(FMDatabase * _Nonnull db, BOOL * _Nonnull rollBack) {
        Person *p = [self createPerson:1 name:@"A"];
        Person *p2 = [self createPerson:2 name:@"B"];

        [db saveObj:p useTransaction:NO];
        [db saveObj:p2 useTransaction:NO];

        *rollBack = YES;
    }];
}

- (void)testFindByID {
    Person *p = [Person jr_findByID:@"CD71B668-3608-4EAE-997A-201DBAE40BA3"];
    [p isEqual:nil];
}

- (void)testDeleteAll {
    [Person jr_truncateTable];
    [Card jr_truncateTable];
}


- (void)testSomething {
    NSArray *array = [Person jr_findAll];
    NSArray *arr = [Card jr_findAll];
    [array isEqual:nil];
    [arr isEqual:nil];
    
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




