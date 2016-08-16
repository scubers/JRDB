//
//  JRDBMgrContextTests.m
//  JRDB
//
//  Created by J on 16/8/16.
//  Copyright © 2016年 Jrwong. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "JRDB.h"
#import "Person.h"
#import "JRColumnSchema.h"
#import "NSObject+Reflect.h"
#import "JRDBChain.h"
#import <objc/runtime.h>


@interface JRDBMgrContextTests : XCTestCase

@end

@implementation JRDBMgrContextTests

- (void)setUp {
    [super setUp];
    
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
