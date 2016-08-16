//
//  JRActivatedProperty.m
//  JRDB
//
//  Created by 王俊仁 on 16/6/13.
//  Copyright © 2016年 Jrwong. All rights reserved.
//

#import "JRActivatedProperty.h"

@implementation JRActivatedProperty

@synthesize name = _name;
@synthesize relateionShip = _relateionShip;

+ (instancetype)property:(NSString *)name relationShip:(JRRelation)relationShip {
    JRActivatedProperty *property = [JRActivatedProperty new];
    property->_name = name;
    property->_relateionShip = relationShip;
    return property;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@: name:%@, databaseName:%@, databaseType:%@, relation:%zd, clazz:%@"
            , @"JRActivatedProperty"
            , self.name
            , self.dataBaseName
            , self.dataBaseType
            , (int)self.relateionShip
            , self.clazz
            ];
}

@end
