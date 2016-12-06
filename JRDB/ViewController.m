//
//  ViewController.m
//  JRDB
//
//  Created by JMacMini on 16/5/10.
//  Copyright © 2016年 Jrwong. All rights reserved.
//

#import "ViewController.h"
#import "JRDB-Swift.h"
#import "JRSqlGenerator.h"
#import "Person.h"
#import "JRDBMgr.h"
#import "FMDB.h"
#import "NSObject+JRDB.h"
#import <objc/runtime.h>
#import "JRDBChain.h"


@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
//    [self test];
//    [self test2];
//    [self test3];
//    [self testOneToManySave];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    AViewController *av = [[AViewController alloc] init];
    [self presentViewController:av animated:YES completion:nil];
}

- (void)test2 {
}

- (void)testOneToManySave {
    id<JRPersistentHandler> db = [[JRDBMgr shareInstance] databaseWithPath:@"/Users/mac/Desktop/test.sqlite"];
    [[JRDBMgr shareInstance] registerClazzes:@[
                                               [Person class],
                                               [Card class],
                                               [Money class],
                                               ]];
    [JRDBMgr shareInstance].defaultDB = db;
    [JRDBMgr shareInstance].debugMode = NO;

    Person *p = [self createPerson:1 name:nil];
    for (int i = 0; i < 100; i++) {
        [p.money addObject:[self createMoney:i]];
    }
    Person *p1 = [self createPerson:1 name:nil];
    for (int i = 0; i < 100; i++) {
        [p1.money addObject:[self createMoney:i]];
    }
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [p1 jr_save];
    });
    NSLog(@"method over");
    
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
