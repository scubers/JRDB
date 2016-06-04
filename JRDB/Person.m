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
@end


@implementation Card
+ (NSDictionary<NSString *,Class<JRPersistent>> *)jr_singleLinkedPropertyNames {
    return @{@"_person" : [Person class]};
}
- (void)dealloc {
    NSLog(@"%@, dealloc", self);
}
- (NSString *)description {
    return [NSString stringWithFormat:@"Serial number: %@\nID: %@", self.serialNumber, self.ID];
}
@end


@implementation Animal
- (void)dealloc {
    NSLog(@"%@, dealloc", self);
}
@end

@implementation Person

+ (NSArray *)jr_excludePropertyNames {
    return @[
//             @"_k_data",
//             @"_l_date",
             @"_m_date",
             ];
}

//+ (NSString *)jr_customPrimarykey {
//    return @"_i_string";
//}
//
//- (id)jr_customPrimarykeyValue {
//    return self.i_string;
//}

+ (NSDictionary<NSString *,Class<JRPersistent>> *)jr_singleLinkedPropertyNames {
    return @{
             @"_card" : [Card class],
             @"_card1" : [Card class],
             @"_son" : [Person class],
             };
}

+ (NSDictionary<NSString *,Class<JRPersistent>> *)jr_oneToManyLinkedPropertyNames {
    return @{
             @"_money" : [Money class],
             };
}

- (NSString *)description {
    return [NSString stringWithFormat:@"name: %@, \nID: %@", self.name, self.ID];
}

- (NSMutableArray<Money *> *)money {
    if (!_money) {
        _money = [NSMutableArray array];
    }
    return _money;
}

@end
