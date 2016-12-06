//
//  JRActivatedProperty.m
//  JRDB
//
//  Created by 王俊仁 on 16/6/13.
//  Copyright © 2016年 Jrwong. All rights reserved.
//

#import "JRActivatedProperty.h"

@implementation JRActivatedProperty


+ (instancetype)property:(NSString *)name relationShip:(JRRelation)relationShip {
    JRActivatedProperty *property = [JRActivatedProperty new];
    property->_propertyName = name;
    property->_relateionShip = relationShip;
    return property;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"JRActivatedProperty: propertyName:%@, ivarName:%@, databaseName:%@, databaseType:%@, relation:%zd, clazz:%@, typeEncoding: %@"
            , self.propertyName
            , self.ivarName
            , self.dataBaseName
            , self.dataBaseType
            , (int)self.relateionShip
            , self.clazz
            , self.typeEncode
            ];
}

@end
