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

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    AViewController *v = [[AViewController alloc] init];
    [self presentViewController:v animated:false completion:nil];
    
    NSString *sql = [JRSqlGenerator createTableSql4Clazz:[Person class]];
    NSLog(@"%@", sql);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
