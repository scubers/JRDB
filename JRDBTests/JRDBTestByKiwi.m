//
//  JRDBTestByKiwi.m
//  JRDB
//
//  Created by 王俊仁 on 2016/11/13.
//  Copyright © 2016年 Jrwong. All rights reserved.
//


#import "JRDB.h"
#import "Person.h"

#import <Kiwi/Kiwi.h>

// J_Select(Person)
// .and.key(name).eq("name")
// .and.key(name1).nq("name")
// .and.key(name2).like("name")
// .or.key("age").gt(10)
// .or.key("number").lt(11)
// .list;
//

Person *createPerson(int base, NSString *name) {
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

Card *createCard(NSString *number) {
    Card *c = [Card new];
    c.serialNumber = number;
    return c;
}

Money *createMoney(int value) {
    Money *m = [Money new];
    m.value = [NSString stringWithFormat:@"%d", value];
    return m;
}

void randomChangePerson(Person *p) {
    p.a_int = 129487;
    p.bbbbb = NO;
    p.c_long = 98987;
    p.d_long_long = 98778;
    p.f_unsigned_long_long = 23425435;
    p.h_double = 9874.4545;
    p.i_string = @"98ujgoijg";
    p.j_number = @23556754;
    p.k_data = [NSData data];
    p.l_date = [NSDate date];
}


BOOL matchObjects(id obj1, id obj2, NSArray<NSString *> *columns) {
    BOOL result = YES;
    for (NSString *keypath in columns) {
        id value1 = [obj1 valueForKey:keypath];
        id value2 = [obj2 valueForKey:keypath];

        if (!value1 && !value2) {
            break;
        }
        if (![value1 isEqual:value2]) {
            result = NO;
            break;
        }
    }
    return result;
}

SPEC_BEGIN(JRDBTestTest)

describe(@"operation test", ^{

    let(db, ^id{
        id<JRPersistentHandler> db = [[JRDBMgr shareInstance] databaseWithPath:@"/Users/mac/Desktop/test11.sqlite"];
        [[JRDBMgr shareInstance] registerClazzes:@[
                                                   [Person class],
                                                   [Card class],
                                                   [Money class],
                                                   ]];
        [JRDBMgr shareInstance].defaultDB = db;

        [JRDBMgr shareInstance].debugMode = YES;
        return db;
    });

    
    
    afterEach(^{
        [JRDBMgr shareInstance].debugMode = NO;
        J_DeleteAll(Person).updateResult;
        J_DeleteAll(Card).updateResult;
        J_DeleteAll(Money).updateResult;
        [[JRDBMgr shareInstance] clearMidTableRubbishDataForDB:db];
        J_DropTable(Person);
        J_DropTable(Card);
        J_DropTable(Money);
        [JRDBMgr shareInstance].debugMode = YES;
    });
    
    // MARK: 普通操作
    context(@"normal operation", ^{
        
        context(@"table operation", ^{
            it(@"create Table", ^{
                J_CreateTable(Person);
                [[@([db tableExists:[Person jr_tableName]]) should] beYes];
            });
        });
        
        context(@"save", ^{
            it(@"save one", ^{
                Person *p = createPerson(0, nil);
                BOOL result = J_Insert(p).updateResult;
                [[theValue(result) should] beYes];
                [[theValue(J_Select(Person).list.count) should] equal:@1];
            });
            
            it(@"save many", ^{
                NSMutableArray *array = [NSMutableArray array];
                for (int i = 0; i < 10; i++) {
                    [array addObject:createPerson(i, nil)];
                }
                BOOL a = J_Insert(array).updateResult;
                [[theValue(a) should] beYes];
                [[theValue(J_Select(Person).list.count) should] equal:@10];
            });
        });
        
        context(@"update", ^{
            
            beforeEach(^{
                for(int i = 0; i < 10; i++) {
                    Person *p = createPerson(i, nil);
                    J_Insert(p).updateResult;
                }
            });
            
            
            it(@"update single", ^{
                NSArray<Person *> *list = J_Select(Person).list;
                Person *p = list[1];
                
                randomChangePerson(p);
                
                BOOL ret = J_Update(p).updateResult;
                [[theValue(ret) should] beYes];
                Person *person = J_Select(Person).WherePKIs([p jr_primaryKeyValue]).object;
                
                ret = matchObjects(p, person, @[
                                                J(a_int),
                                                J(b_unsigned_int),
                                                J(c_long),
                                                J(d_long_long),
                                                J(i_string),
                                                ]);
                [[theValue(ret) should] beYes];
                
            });
            
        });
        
        context(@"select", ^{
            beforeEach(^{
                for(int i = 0; i < 20; i++) {
                    Person *p = createPerson(i, [NSString stringWithFormat:@"person__%d", i]);
                    BOOL result = J_Insert(p).updateResult;
                    [[theValue(result) should] beYes];
                }
            });
            
            it(@"condition select", ^{
                NSArray<Person *> *ps = J_Select(Person).And(@"name").like(@"%1%").Or(@"name").like(@"%7%").list;
                [ps enumerateObjectsUsingBlock:^(Person * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    BOOL result = [obj.name containsString:@"1"]|| [obj.name containsString:@"7"];
                    [[theValue(result) should] beYes];
                }];
            });
            
            it(@"test select", ^{
                NSArray<Person *> *ps = J_Select(Person).And(@"name").like(@"%1%").Or(@"name").like(@"%7%").list;
                [ps enumerateObjectsUsingBlock:^(Person * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    BOOL result = [obj.name containsString:@"1"]|| [obj.name containsString:@"7"];
                    [[theValue(result) should] beYes];
                }];
            });
        });
        
        context(@"delete", ^{
            
            beforeEach(^{
                for(int i = 0; i < 10; i++) {
                    Person *p = createPerson(i, nil);
                    J_Insert(p).updateResult;
                }
            });
            
            it(@"delete some", ^{
                NSArray<Person *> *persons = J_Select(Person).list;
                BOOL ret = J_Delete([persons subarrayWithRange:NSMakeRange(0, 5)]).updateResult;
                [[theValue(ret) should] beYes];
            });
            
        });
    });

    // MARK: 关联操作
    context(@"recursive operation", ^{
        
        it(@"save child", ^{
            Person *p = createPerson(0, nil);
            Person *p1 = createPerson(1, nil);
            p.son = p1;
     
            
            BOOL result = J_Insert(p).Recursively.updateResult;
            [[theValue(result) should] beYes];
            
            Person *person = J_Select(Person).Recursively.WhereIdIs(p.ID).object;
            
            result = matchObjects(person.son, p1, @[
                                           J(name),
                                           J(bbbbb),
                                           J(c_long),
                                           J(d_long_long),
                                           ]);
            
            [[theValue(result) should] beYes];
            
        });
        
        it(@"save one to one", ^{
            Person *p = createPerson(0, nil);
            Card *c = createCard(@"123");
            p.card = c;
            c.person = p;
     
            
            BOOL result = J_Insert(p).Recursively.updateResult;
            [[theValue(result) should] beYes];
            
            Person *person = J_Select(Person).Recursively.WhereIdIs(p.ID).object;
            
            result = matchObjects(person.card, c, @[
                                                    J(serialNumber),
                                                    J(person),
                                                    ]);
            [[theValue(result) should] beYes];
            
            result = matchObjects(c.person, p, @[
                                                    J(name),
                                                    J(card),
                                                    ]);
            [[theValue(result) should] beYes];
        });
        
        it(@"save one to one three cycle", ^{
            Person *p = createPerson(0, nil);
            Person *p1 = createPerson(1, nil);
            Person *p2 = createPerson(2, nil);
            
            p.son = p1;
            p1.son = p2;
            p2.son = p;
            
            
            BOOL result = J_Insert(p).Recursively.updateResult;
            [[theValue(result) should] beYes];
            
            Person *person = J_Select(Person).Recursively.WhereIdIs(p.ID).object;
            
            
            result = matchObjects(person.son, p1, @[
                                                 J(name),
                                                 J(card),
                                                 ]);
            [[theValue(result) should] beYes];
            
            result = matchObjects(person.son.son, p2, @[
                                                 J(name),
                                                 J(card),
                                                 ]);
            [[theValue(result) should] beYes];
            
            result = matchObjects(person.son.son.son, p, @[
                                                 J(name),
                                                 J(card),
                                                 ]);
            [[theValue(result) should] beYes];
        });
        
        it(@"save one to many", ^{
            int count = 10;
            Person *p = createPerson(0, nil);

            for (int i = 0; i < count; i++) {
                Person *p1 = createPerson(1 + i, nil);
                [p.children addObject:p1];
            }
            
            BOOL result = J_Insert(p).Recursively.updateResult;
            [[theValue(result) should] beYes];
            
            Person *person = J_Select(Person).Recursively.WhereIdIs(p.ID).object;
            
            [[theValue(person.children.count) should] equal:@(count)];
            
            [person.children enumerateObjectsUsingBlock:^(Person * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                
                BOOL result = matchObjects(obj, p.children[idx]
                                      , @[
                                          J(name),
                                          J(bbbbb),
                                          J(c_long),
                                          J(d_long_long),
                                          ]);
                [[theValue(result) should] beYes];
            }];
            
        });
        
        it(@"save one to many 2", ^{
            int count = 10;
            Person *p = createPerson(0, nil);
            
            for (int i = 0; i < count; i++) {
                Money *m = createMoney(i);
                [p.money addObject:m];
            }
            
            BOOL result = J_Insert(p).Recursively.updateResult;
            [[theValue(result) should] beYes];
            
            Person *person = J_Select(Person).Recursively.WhereIdIs(p.ID).object;
            [[theValue(person.money.count) should] equal:@(count)];
            
            [person.money enumerateObjectsUsingBlock:^(Money * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                
                BOOL result = matchObjects(obj, p.money[idx]
                                           , @[
                                               @"value",
                                               ]);
                [[theValue(result) should] beYes];
            }];
            
        });
        
        it(@"update many", ^{
            int count = 10;
            Person *p = createPerson(0, nil);
            
            for (int i = 0; i < count; i++) {
                Money *m = createMoney(i);
                [p.money addObject:m];
            }
            
            BOOL result = J_Insert(p).Recursively.updateResult;
            [[theValue(result) should] beYes];
            
            Person *person = J_Select(Person).WhereIdIs(p.ID).Recursively.object;
            [[theValue(person.money.count) should] equal:@(count)];
            person.money = nil;

            
            result = J_Update(person).Recursively.updateResult;
            [[theValue(result) should] beYes];
            
            person = J_Select(Person).WhereIdIs(p.ID).Recursively.object;
            [[theValue(person.money.count) should] equal:@0];
        });
    });
});

SPEC_END
