//
//  JRExtraProperty.h
//  JRDB
//
//  Created by 王俊仁 on 16/6/5.
//  Copyright © 2016年 Jrwong. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JRExtraProperty : NSObject

@property (nonatomic, strong, nonnull, readonly) Class    linkClazz;
@property (nonatomic, copy, nonnull, readonly  ) NSString *dbLinkKey;
@property (nonatomic, copy, nullable, readonly ) NSString *linkKey;

+ (instancetype _Nonnull)extraPropertyWithClazz:(Class _Nonnull)clazz linkKey:(NSString * _Nonnull)key;

@end
