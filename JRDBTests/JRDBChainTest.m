//
//  JRDBChainTest.m
//  JRDB
//
//  Created by JMacMini on 16/7/13.
//  Copyright © 2016年 Jrwong. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "JRDB.h"
#import "Person.h"
#import "JRColumnSchema.h"
#import "NSObject+Reflect.h"
#import "JRDBChain.h"
#import <objc/runtime.h>


@interface JRDBChainTest : XCTestCase

@end

@implementation JRDBChainTest

- (void)setUp {
    [super setUp];
    [JRDBMgr defaultDB];
    FMDatabase *db = [[JRDBMgr shareInstance] createDBWithPath:@"/Users/mac/Desktop/test.sqlite"];
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
    
    [[JRDBMgr defaultDB] jr_closeQueue];
    [[JRDBMgr defaultDB] close];
    [super tearDown];
    
    
}

- (void)testAAAAA {
    [J_Select(Person) exe:nil];
}

#pragma mark - Delete
- (void)testDeleteAll {
    [J_DeleteAll([Person class]).Recursive(YES) exe:nil];
    [J_DeleteAll([Money class]).Recursive(YES) exe:nil];
    [J_DeleteAll([Card class]).Recursive(YES) exe:nil];
    
//    [J_DELETEALL([Person class]).Recursive(NO) exe:nil];
//    [J_DELETEALL([Money class]).Recursive(NO) exe:nil];
//    [J_DELETEALL([Card class]).Recursive(NO) exe:nil];
}

- (void)testDeleteOne {
    Person *p = [[J_Select(Person) exe:nil] firstObject];
    [J_Delete(p).Recursive(NO) exe:nil];
//    [J_DELETE(p).Recursive(YES) exe:nil];
}

- (void)testDeleteMany {
    NSArray *array = [J_Select(Person) exe:nil];
    [J_Delete(array).Recursive(NO) exe:nil];
//    [J_DELETE(array).Recursive(YES) exe:nil];
}

#pragma mark - Insert

- (void)testSaveOne {
    NSLog(@"default db: %@", [JRDBMgr defaultDB]);
    Person *p = [self createPerson:1 name:nil];
    [J_Insert(p).Recursive(NO).Sync(YES) exe:nil];
}

- (void)testSaveMany {
    NSMutableArray *array = [NSMutableArray array];
    for (int i = 0; i < 10; i++) {
        [array addObject:[self createPerson:i name:nil]];
    }
//    [array jr_save];
    [J_Insert(array).Recursive(NO) exe:nil];
}

- (void)testSaveOneWithSituation {
    Person *p = [self createPerson:1 name:nil];
    p.son = [self createPerson:2 name:nil];
    p.card = [self createCard:@"1111"];
    p.card.person = p;
    for (int i = 0; i < 10; i++) {
        [p.money addObject:[self createMoney:i]];
        [p.children addObject:[self createPerson:i+10 name:nil]];
    }
//    [J_INSERT(p).Recursive(NO) exe:nil];
    [J_Insert(p).Recursive(YES) exe:nil];

    [J_Insert(p)
     .InDB([JRDBMgr defaultDB])
     .Recursive(YES)
     .Sync(YES)
     .Transaction(YES)
     exe:nil];
}

- (void)testSaveCycle {
    Person *p = [self createPerson:1 name:nil];
    p.son = [self createPerson:2 name:nil];
    p.card = [self createCard:@"1111"];
    p.card.person = p;
    [J_Insert(p).Recursive(YES) exe:nil];
//    [J_INSERT(p).Recursive(NO) exe:nil];
}

- (void)testSave3Cycle {
    Person *p1 = [self createPerson:1 name:nil];
    Person *p2 = [self createPerson:2 name:nil];
    Person *p3 = [self createPerson:3 name:nil];
    p1.son = p2;
    p2.son = p3;
    p3.son = p1;
    
    [J_Insert(p1).Recursive(YES) exe:nil];
//    [J_INSERT(p2).Recursive(YES) exe:nil];
//    [J_INSERT(p3).Recursive(YES) exe:nil];
    
//    [J_INSERT(p1).Recursive(NO) exe:nil];
//    [J_INSERT(p2).Recursive(NO) exe:nil];
//    [J_INSERT(p3).Recursive(NO) exe:nil];
}

- (void)testSaveOneToMany {
    Person *p = [self createPerson:1 name:nil];
    for (int i = 0; i < 10; i++) {
        [p.money addObject:[self createMoney:i]];
    }
    //    [J_INSERT(p).Recursive(NO) exe:nil];
    [J_Insert(p).Recursive(YES) exe:nil];
}

- (void)testSaveChildren {
    Person *p = [self createPerson:1 name:nil];
    for (int i = 0; i < 10; i++) {
        [p.children addObject:[self createPerson:i+10 name:nil]];
    }
    //    [J_INSERT(p).Recursive(NO) exe:nil];
    [J_Insert(p).Recursive(YES) exe:nil];
}

#pragma mark - Update

- (void)testUpdateOne {
    Person *p = [Person jr_findAll].firstObject;
    p.a_int = 1212;
    [J_Update(p).Recursive(YES).ColumnsJ(J(Person, a_int), J(Person, name)) exe:nil];
    [J_Update(p).Recursive(NO) exe:nil];

}

- (void)testUpdateMany {
    NSArray<Person *> *ps = [Person jr_findAll];
    [ps enumerateObjectsUsingBlock:^(Person * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.c_long = 9999;
    }];
    [J_Update(ps).Recursive(YES) exe:nil];
//    [J_UPDATE(ps).Recursive(NO) exe:nil];
}

- (void)testUpdateCycle1 {
    Person *p = [Person jr_findAll].firstObject;
    p.card = nil;
//    p.card = [self createCard:@"1123"];
    [J_Update(p).Recursive(YES) exe:nil];
//    [J_UPDATE(p).Recursive(NO) exe:nil];
}

- (void)testUpdateCycle2 {
    Person *p = [Person jr_findAll].firstObject;
    p.son = nil;
//    p.son = [self createPerson:10 name:nil];
    [J_Update(p).Recursive(YES) exe:nil];
//    [J_UPDATE(p).Recursive(NO) exe:nil];
}

- (void)testUpdateOneToMany {
    Person *p = [Person jr_findAll].firstObject;
    p.money = nil;
//    for (int i = 0; i < 10; i++) {
//        [p.money addObject:[self createMoney:i]];
//    }
//    [p.money removeLastObject];
    [J_Update(p).Recursive(YES) exe:nil];
//    [J_UPDATE(p).Recursive(NO) exe:nil];
}

- (void)testUpdateColumns {
    Person *p = [Person jr_findAll].firstObject;
    p.son = [self createPerson:2 name:nil];
    p.card = [self createCard:@"1111"];
    p.card.person = p;
    for (int i = 0; i < 10; i++) {
        [p.money addObject:[self createMoney:i]];
        [p.children addObject:[self createPerson:i+10 name:nil]];
    }
    [J_Update(p).ColumnsJ(J(Person, a_int)).Recursive(YES) exe:nil];
}

- (void)testUpdateIgnore {
    Person *p = [Person jr_findAll].firstObject;
    p.son = [self createPerson:2 name:nil];
    p.card = [self createCard:@"1111"];
    p.card.person = p;
    for (int i = 0; i < 10; i++) {
        [p.money addObject:[self createMoney:i]];
        [p.children addObject:[self createPerson:i+10 name:nil]];
    }
    [J_Update(p).IgnoreJ(J(Person, a_int)).Recursive(YES) exe:nil];
}

#pragma mark - save or update

- (void)testSaveOrUpdate {
    Person *p = [Person jr_findAll].firstObject;
    p.a_int = 1122;
    [J_SaveOrUpdate(p) exe:^(JRDBChain * _Nonnull chain, id  _Nullable result) {
        NSLog(@"%@", result);
    }];
}


#pragma mark - Select

- (void)testSelectByID {
    Person *p = [[J_Select(Person) exe:nil] firstObject];
    
    Person *p1 = [J_Select(Person).WherePKIs(p.ID) exe:nil];
    Person *p2 = [J_Select(Person).WherePKIs(p.ID).Cache(YES) exe:nil];
    [p1 isEqual:p2];

    
}

- (void)testSelectAll {
    
    NSArray<Person *> *ps2 = [J_Select(Person).Cache(NO) exe:nil];
    NSArray<Person *> *ps = [J_Select([Person class]).Recursive(YES).Cache(NO) exe:nil];
    NSArray<Person *> *ps1 = [J_Select([Person class]).Recursive(YES).Cache(NO) exe:nil];
    NSLog(@"%@", ps);
    NSLog(@"%@", ps1);
    NSLog(@"%@", ps2);
    
    id result = J_Select(Person)
                    .Recursive(YES)
                    .Sync(YES)
                    .Cache(YES)
                    .WhereJ(_name like ? and _height > ?)
                    .ParamsJ(@"a%", @100)
                    .GroupJ(Person, h_double)
                    .OrderJ(Person, d_long_long)
                    .Limit(0, 10)
                    .Desc(YES);

    NSLog(@"%@", result);

    [J_Update(ps.firstObject)
     .ColumnsJ(J(Person, a_int),J(Person, b_unsigned_int))
     
     exe:nil];
}

- (void)testOtherCondition {
    NSArray<Person *> *ps =
    [J_Select(Person)
    .Recursive(YES)
    .FromJ(Person)
    .OrderJ(Person, a_int)
    .GroupJ(Person, bbbbb)
    .Limit(0,3)
    .Desc(YES)
     exe:nil];
    ;

    NSLog(@"%@", ps);
}

- (void)testSelectCount {
    NSNumber *count =
    [J_SelectCount(Person)
    .OrderJ(Person,a_int)
    .GroupJ(Person,b_unsigned_int)
    .Limit(0, 3)
    .Desc(YES)
     exe:nil];

    NSLog(@"%@", count);
}

- (void)testSelectColumn {
    NSArray<Person *> *ps =
    [J_SelectColumns(J(Person, a_int), J(Person, b_unsigned_int))
    .Recursive(YES) // 自定义查询，即使设置关联查询，也不会进行关联查询
    .FromJ(Person)
    .OrderJ(Person, a_int)
    .GroupJ(Person, j_number)
    .Limit(0, 3)
    .Desc(YES)
     exe:nil];


    NSLog(@"%@", ps);
}

- (void)testGCD {
//    [JRDBMgr shareInstance].debugMode = NO;
    
    NSMutableArray *ori = [NSMutableArray array];
    int count = 100;
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [J_Select(Person) exe:^(JRDBChain * _Nonnull chain, id  _Nullable result) {
            NSLog(@"%@", result);
        }];
    });
    
    sleep(5);
    return;
    for (int i = 0; i<count; i++) {
        [ori addObject:@(i)];
        
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            id result = [J_Select(Person).Recursive(YES).Sync(YES) exe:^(JRDBChain * _Nonnull chain, id  _Nullable result) {
                NSLog(@"___complete %@", @([result count]));
            }];
            NSLog(@"=+=+=+=+  %@", @([result count]));
//            [J_INSERT([self createPerson:i name:nil]).Sync(YES) exe:^(JRDBChain * _Nonnull chain, id  _Nullable result) {
//                NSLog(@"%@", result);
//            }];
        });
    }
    
//    sleep(100);
}

- (void)testGCD2 {
    [Person jr_deleteAll];
    NSMutableArray *p = [NSMutableArray array];
    for (int i = 0; i < 10; i++) {
        [p addObject:[self createPerson:i name:nil]];
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            [[JRDBMgr defaultDB] jr_inTransaction:^(FMDatabase * _Nonnull db, BOOL * _Nonnull rollBack) {
                id a = [J_Insert(p[i]).InDB(db).Sync(NO) exe:nil];
                NSLog(@"%@", a);
            }];
        });
    }
    
    sleep(5);
}

#pragma mark - convenience method
- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
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

- (void)abc:(int[])aa {

}

@end
