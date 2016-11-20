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




SPEC_BEGIN(JRDBTss)


describe(@"normal operation test", ^{

    let(db, ^id{
        id<JRPersistentHandler> db = [[JRDBMgr shareInstance] databaseWithPath:@"/Users/Jrwong/Desktop/test11.sqlite"];
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
        J_DeleteAll(Person).updateResult;
        J_DeleteAll(Card).updateResult;
        J_DeleteAll(Money).updateResult;
        [[JRDBMgr shareInstance] clearMidTableRubbishDataForDB:db];
        J_DropTable(Person);
        J_DropTable(Card);
        J_DropTable(Money);
    });

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

});

SPEC_END
