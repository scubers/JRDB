//
//  Person.h
//  JRDB
//
//  Created by JMacMini on 16/5/10.
//  Copyright © 2016年 Jrwong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JRPersistent.h"

@class Person;

@interface Money : NSObject
@property (nonatomic, strong) NSString *value;
@end

@interface Card : NSObject
@property (nonatomic, strong) NSString *serialNumber;
@property (nonatomic, weak) Person *person;
@end


@interface Animal : NSObject

@property (nonatomic, strong) NSString *type;

@end


@interface Person : Animal

@property (nonatomic, strong) Animal *animal;


@property (nonatomic, strong) NSString *name;
@property (nonatomic, assign) int a_int;
@property (nonatomic, assign) unsigned int b_unsigned_int;
@property (nonatomic, assign) long c_long;
@property (nonatomic, assign) long long d_long_long;
@property (nonatomic, assign) unsigned long e_unsigned_long;
@property (nonatomic, assign) unsigned long long f_unsigned_long_long;

@property (nonatomic, assign) float g_float;
@property (nonatomic, assign) double h_double;

@property (nonatomic, strong) NSString *i_string;
@property (nonatomic, strong) NSNumber *j_number;
@property (nonatomic, strong) NSData *k_data;
@property (nonatomic, strong) NSDate *l_date;
@property (nonatomic, strong) NSDate *m_date;


@property (nonatomic, strong) Person *son;

@property (nonatomic, strong) Card *card;
@property (nonatomic, strong) Card *card1;


@property (nonatomic, strong) NSMutableArray<Money *> *money;

@property (nonatomic, strong) NSMutableArray<Person *> *children;


@end
