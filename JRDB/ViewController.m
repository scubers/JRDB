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
#import <FMDB.h>
#import "FMDatabase+JRDB.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
//    [self test];
    [self test2];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    AViewController *av = [[AViewController alloc] init];
    [self presentViewController:av animated:YES completion:nil];
}

- (void)test2 {
    FMDatabase *db = [[JRDBMgr shareInstance] createDBWithPath:@"/Users/jmacmini/Desktop/aaa.sqlite"];
    Person *p = [db findAll:[Person class]].firstObject;
    p.a_int = 2222;
    
    if ([db updateObj:p columns:nil]) {
        NSLog(@"success");
    } else {
        NSLog(@"failure");
    }
    
//    NSLog(@"%@", arr);
}

- (void)test {
    FMDatabase *db = [[JRDBMgr shareInstance] createDBWithPath:@"/Users/jmacmini/Desktop/aaa.sqlite"];
    Person *p = [[Person alloc] init];
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
    
    if ([db saveObj:p]) {
        NSLog(@"success");
    } else {
        NSLog(@"failure");
    }
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
