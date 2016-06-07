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
#import "FMDatabase+JRDB.h"
#import "JRQueryCondition.h"
#import "NSObject+JRDB.h"
#import <objc/runtime.h>


@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
//    [self test];
//    [self test2];
//    [self test3];

}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    AViewController *av = [[AViewController alloc] init];
    [self presentViewController:av animated:YES completion:nil];
}

- (void)test2 {
    FMDatabase *db = [JRDBMgr defaultDB];
    NSArray *array = [db jr_findAll:[Person class]];
    
    
    NSLog(@"%@", array);
}

@end
