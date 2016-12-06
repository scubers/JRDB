//
//  Person.m
//  JRDB
//
//  Created by JMacMini on 16/5/10.
//  Copyright © 2016年 Jrwong. All rights reserved.
//

#import "Person.h"
#import "NSObject+JRDB.h"

@implementation Money

+ (NSString *)jr_tableName {
    return @"my_money";
}

@end


@implementation Card

+ (NSString *)jr_tableName {
    return @"my_card";
}

+ (NSDictionary<NSString *,Class<JRPersistent>> *)jr_singleLinkedPropertyNames {
    return @{@"person" : [Person class]};
}
- (void)dealloc {
    NSLog(@"%@, dealloc", self);
}
@end


@implementation Animal
- (void)dealloc {
//    NSLog(@"%@, dealloc", self);
}
@end

@implementation Person

+ (NSString *)jr_tableName {
    return @"my_person";
}

+ (NSArray *)jr_excludePropertyNames {
    return @[
//             @"k_data",
//             @"l_date",
             @"m_date",
             ];
}

+ (NSDictionary<NSString *,Class<JRPersistent>> *)jr_singleLinkedPropertyNames {
    return @{
             @"card" : [Card class],
             @"card1" : [Card class],
             @"cccc" : [Card class],
             @"son" : [Person class],
             };
}

+ (NSDictionary<NSString *,Class<JRPersistent>> *)jr_oneToManyLinkedPropertyNames {
    return @{
             @"money" : [Money class],
             @"children" : [Person class],
             @"nnnn" : [Person class],
             };
}

//+ (NSString *)jr_customPrimarykey {
//    return @"i_string";
//}
//
//- (id)jr_customPrimarykeyValue {
//    return self.i_string;
//}

- (NSMutableArray<Money *> *)money {
    if (!_money) {
        _money = [NSMutableArray array];
    }
    return _money;
}
- (NSMutableArray<Person *> *)children {
    if (!_children) {
        _children = [NSMutableArray array];
    }
    return _children;
}

@end
