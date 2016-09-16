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
    
    [[JRDBMgr defaultDB] close];
    [super tearDown];
}

#pragma mark - table

- (void)testAAAAACreateTable {
    BOOL a = J_CreateTable(Person);
    NSAssert(a, @"~~ error: %s", __FUNCTION__);
}

- (void)testAAAAUpdateTable {
    BOOL a = J_UpdateTable(Person);
    NSAssert(a, @"~~ error: %s", __FUNCTION__);
}

- (void)testAAAATruncateTable {
    BOOL a = J_TruncateTable(Person);
    NSAssert(a, @"~~ error: %s", __FUNCTION__);
}

- (void)testAAADropTable {
    BOOL a = J_DropTable(Person);
    NSAssert(a, @"~~ error: %s", __FUNCTION__);
}

#pragma mark - table schema

- (void)testTableSchema {
    [[JRDBMgr defaultDB] jr_schemasInClazz:[Person class]];
}

#pragma mark - Delete

#ifdef aaa
- (void)testZZZDeleteAll {
    [self testSaveMany];
    BOOL a = J_DeleteAll(Person).Recursive(YES).updateResult;
    BOOL b = J_DeleteAll(Money).Recursive(YES).updateResult;
    BOOL c = J_DeleteAll(Card).Recursive(YES).updateResult;
    
    NSAssert(a && b && c, @"~~ error: %s", __FUNCTION__);
//    [J_DELETEALL([Person class]).Recursive(NO) exe:nil];
//    [J_DELETEALL([Money class]).Recursive(NO) exe:nil];
//    [J_DELETEALL([Card class]).Recursive(NO) exe:nil];
}
- (void)testZZZDeleteAll1 {
    [self testSaveMany];
    BOOL a = J_DeleteAll(Person).Recursive(NO).updateResult;
    BOOL b = J_DeleteAll(Money).Recursive(NO).updateResult;
    BOOL c = J_DeleteAll(Card).Recursive(NO).updateResult;
    
    NSAssert(a && b && c, @"~~ error: %s", __FUNCTION__);
//    [J_DELETEALL([Person class]).Recursive(NO) exe:nil];
//    [J_DELETEALL([Money class]).Recursive(NO) exe:nil];
//    [J_DELETEALL([Card class]).Recursive(NO) exe:nil];
}

- (void)testZDeleteOne {
    [self testSaveMany];
    Person *p = J_Select(Person).list.firstObject;
    BOOL a = J_Delete(p).Recursive(NO).updateResult;
    NSAssert(a, @"~~ error: %s", __FUNCTION__);
//    [J_DELETE(p).Recursive(YES) exe:nil];
}

- (void)testZDeleteOne1 {
    [self testSaveMany];
    Person *p = J_Select(Person).list.firstObject;
    BOOL a = J_Delete(p).Recursive(YES).updateResult;
    NSAssert(a, @"~~ error: %s", __FUNCTION__);
    //    [J_DELETE(p).Recursive(YES) exe:nil];
}

- (void)testZZDeleteMany {
    [self testSaveMany];
    NSArray *array = J_Select(Person).list;
    BOOL a = J_Delete(array).Recursive(NO).updateResult;
    NSAssert(a, @"~~ error: %s", __FUNCTION__);
//    [J_DELETE(array).Recursive(YES) exe:nil];
}
- (void)testZZDeleteMany1 {
    [self testSaveMany];
    NSArray *array = J_Select(Person).list;
    BOOL a = J_Delete(array).Recursive(YES).updateResult;
    NSAssert(a, @"~~ error: %s", __FUNCTION__);
//    [J_DELETE(array).Recursive(YES) exe:nil];
}

- (void)testZZZZZDeleteDatabase {
    [[JRDBMgr shareInstance] deleteDatabaseWithPath:[JRDBMgr defaultDB].databasePath];
}


#endif /* aaa */

#pragma mark - Insert

- (void)testSaveOne {
    NSLog(@"default db: %@", [JRDBMgr defaultDB]);
    Person *p = [self createPerson:1 name:nil];
    BOOL a = J_Insert(p).Recursive(NO).Sync(YES).updateResult;
    NSAssert(a, @"~~ error: %s", __FUNCTION__);
}

- (void)testSaveMany {
    NSMutableArray *array = [NSMutableArray array];
    for (int i = 0; i < 10; i++) {
        [array addObject:[self createPerson:i name:nil]];
    }
//    [array jr_save];
    BOOL a = J_Insert(array).Recursive(NO).updateResult;
    NSAssert(a, @"~~ error: %s", __FUNCTION__);
}

- (void)testSaveMany1 {
    NSMutableArray *array = [NSMutableArray array];
    for (int i = 0; i < 10; i++) {
        [array addObject:[self createPerson:i name:nil]];
    }
    //    [array jr_save];
    BOOL a = J_Insert(array).Recursive(YES).updateResult;
    NSAssert(a, @"~~ error: %s", __FUNCTION__);
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
    BOOL a = J_Insert(p).Recursive(YES).updateResult;
    NSAssert(a, @"~~ error: %s", __FUNCTION__);
}

- (void)testSaveCycle {
    Person *p = [self createPerson:1 name:nil];
    p.son = [self createPerson:2 name:nil];
    p.card = [self createCard:@"1111"];
    p.card.person = p;
    BOOL a = J_Insert(p).Recursive(YES).updateResult;
    NSAssert(a, @"~~ error: %s", __FUNCTION__);
//    [J_INSERT(p).Recursive(NO) exe:nil];
}

- (void)testSave3Cycle {
    Person *p1 = [self createPerson:1 name:nil];
    Person *p2 = [self createPerson:2 name:nil];
    Person *p3 = [self createPerson:3 name:nil];
    p1.son = p2;
    p2.son = p3;
    p3.son = p1;
    
    BOOL a = J_Insert(p1).Recursive(YES).updateResult;
    NSAssert(a, @"~~ error: %s", __FUNCTION__);
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
    BOOL a = J_Insert(p).Recursive(YES).updateResult;
    NSAssert(a, @"~~ error: %s", __FUNCTION__);
    
    p = J_Select(Person).WhereIdIs(p.ID).Recursively.object;
    NSLog(@"%@", p);
}

- (void)testSaveChildren {
    Person *p = [self createPerson:1 name:nil];
    for (int i = 0; i < 10; i++) {
        [p.children addObject:[self createPerson:i+10 name:nil]];
    }
    //    [J_INSERT(p).Recursive(NO) exe:nil];
    BOOL a = J_Insert(p).Recursive(YES).updateResult;
    NSAssert(a, @"~~ error: %s", __FUNCTION__);
    p = [Person jr_findByID:p.ID];
    NSLog(@"%@", p);
}

#pragma mark - Update

- (void)testUpdateOne {
    Person *p = J_Select(Person).Recursively.list.firstObject;
    p.a_int = 1111;
    BOOL a = J_Update(p).ColumnsJ(J(a_int), J(name)).Recursively.updateResult;
    NSAssert(a, @"~~ error: %s", __FUNCTION__);
}

- (void)testUpdateMany {
    NSArray<Person *> *ps = [Person jr_findAll];
    [ps enumerateObjectsUsingBlock:^(Person * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.c_long = 9999;
    }];
    BOOL a = J_Update(ps).Recursive(YES).updateResult;
    NSAssert(a, @"~~ error: %s", __FUNCTION__);
//    [J_UPDATE(ps).Recursive(NO) exe:nil];
}

- (void)testUpdateMany1 {
    NSArray<Person *> *ps = [Person jr_getAll];
    [ps enumerateObjectsUsingBlock:^(Person * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.c_long = 9999;
    }];
    BOOL a = J_Update(ps).updateResult;
    NSAssert(a, @"~~ error: %s", __FUNCTION__);
//    [J_UPDATE(ps).Recursive(NO) exe:nil];
}

- (void)testUpdateCycle1 {
    Person *p = [Person jr_findAll].firstObject;
    p.card = nil;
//    p.card = [self createCard:@"1123"];
    BOOL a = J_Update(p).Recursive(YES).updateResult;
    NSAssert(a, @"~~ error: %s", __FUNCTION__);
//    [J_UPDATE(p).Recursive(NO) exe:nil];
}

- (void)testUpdateCycle2 {
    Person *p = [Person jr_findAll].firstObject;
    p.son = nil;
//    p.son = [self createPerson:10 name:nil];
    BOOL a = J_Update(p).Recursive(YES).updateResult;
    NSAssert(a, @"~~ error: %s", __FUNCTION__);
//    [J_UPDATE(p).Recursive(NO) exe:nil];
}

- (void)testUpdateOneToMany {
    Person *p = [Person jr_findAll].firstObject;
    p.money = nil;
//    for (int i = 0; i < 10; i++) {
//        [p.money addObject:[self createMoney:i]];
//    }
//    [p.money removeLastObject];
    BOOL a = J_Update(p).Recursive(YES).updateResult;
    NSAssert(a, @"~~ error: %s", __FUNCTION__);
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
    BOOL a = J_Update(p).ColumnsJ(J(a_int)).Recursive(YES).updateResult;
    NSAssert(a, @"~~ error: %s", __FUNCTION__);
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
    BOOL a = J_Update(p).IgnoreJ(J(a_int)).Recursive(YES).updateResult;
    NSAssert(a, @"~~ error: %s", __FUNCTION__);
}

#pragma mark - save or update

- (void)testSaveOrUpdate {
    Person *p = [Person jr_findAll].firstObject;
    p.a_int = 1122;
    JRDBResult *a = [J_SaveOrUpdate(p) exe:^(JRDBChain * _Nonnull chain, id  _Nullable result) {
        NSLog(@"%@", result);
    }];
    NSAssert(a.flag, @"~~ error: %s", __FUNCTION__);
}

- (void)testSaveOrUpdate1 {
    Person *p = [self createPerson:1 name:nil];
    p.a_int = 1122;
    BOOL a = J_SaveOrUpdate(p).updateResult;
    NSAssert(a, @"~~ error: %s", __FUNCTION__);
}

- (void)testSaveOrUpdate2 {
    Person *p = [self createPerson:1 name:nil];
    p.a_int = 1122;
    BOOL a = [JRDBChain new].SaveOrUpdateOne(p).Recursive(YES).updateResult;
    NSAssert(a, @"~~ error: %s", __FUNCTION__);
}

- (void)testSaveOrUpdate3 {
    NSMutableArray *array = [[Person jr_findAll] mutableCopy];
    for (int i = 0; i < 10; i++) {
        [array addObject:[self createPerson:100 name:nil]];
    }
    BOOL a = [JRDBChain new].SaveOrUpdate(array).updateResult;
    NSAssert(a, @"~~ error: %s", __FUNCTION__);
}

- (void)testSaveOrUpdate4 {
    NSMutableArray *array = [[Person jr_findAll] mutableCopy];
    for (int i = 0; i < 10; i++) {
        [array addObject:[self createPerson:100 name:nil]];
    }
    BOOL a = [JRDBChain new].SaveOrUpdate(array).Recursive(YES).updateResult;
    NSAssert(a, @"~~ error: %s", __FUNCTION__);
}



#pragma mark - Select

- (void)testSelectByID {
    Person *p = J_Select(Person).list.firstObject;
    Person *p1 = J_Select(Person).WherePKIs(p.ID).object;
    Person *p2 = J_Select(Person).WherePKIs(p.ID).Cache(YES).object;
    [p1 isEqual:p2];
    
    [[JRDBMgr defaultDB] jr_getByID:p.ID clazz:[Person class] synchronized:YES useCache:NO complete:^(id  _Nullable result) {
    }];
    

    p = J_Select(Person).list.firstObject;
    p1 = J_Select(Person).WherePKIs(p.ID).object;
    p2 = J_Select(Person).WherePKIs(p.ID).Cache(YES).object;
    [p1 isEqual:p2];
    

}

- (void)testSelectAll {
    
    NSArray<Person *> *ps2 = J_Select(Person).NoCached.list;
    NSArray<Person *> *ps = J_Select(Person).Recursively.NoCached.list;
    NSArray<Person *> *ps1 = J_Select(Person).Recursively.NoCached.list;
    NSLog(@"%@", ps);
    NSLog(@"%@", ps1);
    NSLog(@"%@", ps2);
    
    id result = J_Select(Person)
                    .WhereJ(_name like ? and _height > ?)
                    .ParamsJ(@"a%", @100)
                    .GroupJ(h_double)
                    .OrderJ(d_long_long)
                    .Limit(0, 10)
                    .Descend
                    .Recursively
                    .Safely
                    .Cached
                    .Transactional;

    NSLog(@"%@", result);

    [J_Update(ps.firstObject).ColumnsJ(J(a_int),J(b_unsigned_int)) exe:nil];
}

- (void)testOtherCondition {
    NSArray<Person *> *ps =
    J_Select(Person)
    .Recursive(YES)
    .FromJ(Person)
    .OrderJ(a_int)
    .GroupJ(bbbbb)
    .Limit(0,3)
    .Desc(YES)
    .list;
    ;

    NSLog(@"%@", ps);
}

- (void)testSelectCount {
    NSUInteger count =
    J_SelectCount(Person)
    .OrderJ(a_int)
    .GroupJ(b_unsigned_int)
    .Limit(0, 3)
    .Desc(YES)
    .count;
    
    Person *p = [Person jr_findAll].firstObject;
    
    [[JRDBMgr defaultDB] jr_count4ID:p.ID clazz:[Person class] synchronized:YES complete:^(id  _Nullable result) {
    }];
    
    [[JRDBMgr defaultDB] jr_count4PrimaryKey:[p jr_primaryKeyValue] clazz:[Person class] synchronized:YES complete:^(id  _Nullable result) {
    }];

    NSLog(@"%zd", count);
}

- (void)testSelectColumn {
    NSArray<Person *> *ps =
    J_SelectColumns(J(a_int), J(b_unsigned_int))
    .Recursive(YES) // 自定义查询，即使设置关联查询，也不会进行关联查询
    .FromJ(Person)
    .OrderJ(a_int)
    .GroupJ(j_number)
    .Limit(0, 3)
    .Desc(YES)
    .list;


    NSLog(@"%@", ps);
}

- (void)testFindById {
    Person *p = J_Select(Person).Recursively.WhereIdIs(@"400AF7F3-ADFC-4E6A-B46A-A53EDDA39AEB").object;
    NSLog(@"%@", p);
}

- (void)testSubQuery {
    NSUInteger count =
//    J_SelectColumns(J(a_int), J(e_unsigned_long))
//    J_Select(Person)
    J_SelectCount(Person)
    .From(J_Select(Person).Limit(0,5))
    .OrderJ(e_unsigned_long).Recursively.Descend.count;
    NSLog(@"%@", @(count));
    
    J_Select(Person).WhereJ(a_int = ?).ParamsJ(@10).list;
    
    
    
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
    
//    sleep(5);
    return;
    for (int i = 0; i<count; i++) {
        [ori addObject:@(i)];
        
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            JRDBResult *result = [J_Select(Person).Recursive(YES).Sync(YES) exe:^(JRDBChain * _Nonnull chain, id  _Nullable result) {
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
                BOOL a = J_Insert(p[i]).InDB(db).Sync(NO).updateResult;
                NSLog(@"%d", a);
            }];
        });
    }
    
//    sleep(5);
}


- (void)testTemp {
    
    [[JRDBChain new] exe:^(JRDBChain * _Nonnull chain, id  _Nullable result) {
        
    }];
    
    
    
    [[JRDBChain new].db jr_inTransaction:^(FMDatabase * _Nonnull db, BOOL * _Nonnull rollBack) {
        
    }];

}

#pragma mark - database operation

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


@end
