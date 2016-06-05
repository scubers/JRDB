//
//  JRExtraProperty.m
//  JRDB
//
//  Created by 王俊仁 on 16/6/5.
//  Copyright © 2016年 Jrwong. All rights reserved.
//

#import "JRExtraProperty.h"
#import "JRPersistent.h"

@implementation JRExtraProperty
@synthesize linkClazz = _linkClazz;
@synthesize linkKey = _linkKey;
+ (instancetype)extraPropertyWithClazz:(Class)clazz linkKey:(NSString *)key {
    JRExtraProperty *p = [JRExtraProperty new];
    p->_linkClazz = clazz;
    p->_linkKey = OneToManyLinkColumn(self, key);
    return p;
}
@end
