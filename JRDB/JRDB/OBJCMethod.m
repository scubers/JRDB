//
//  OBJCMethod.m
//  JRDB
//
//  Created by 王俊仁 on 16/6/5.
//  Copyright © 2016年 Jrwong. All rights reserved.
//

#import "OBJCMethod.h"

#define TONSString(s) [NSString stringWithUTF8String:s]

@interface OBJCMethod()
{
    Method _method;
}

@end

@implementation OBJCMethod

+ (instancetype)method:(Method)method {
    OBJCMethod *m = [[OBJCMethod alloc] init];
    m->_method = method;
    return m;
}

- (NSString *)typeEncoding {
    return TONSString(method_getTypeEncoding(_method));
}

- (NSString *)returnType {
    return TONSString(method_copyReturnType(_method));
}

- (SEL)selector {
    return method_getName(_method);
}

- (void *)sendToTarget:(id)target, ... {
    void * retVal;
    va_list args;
    va_start(args, target);
    [self _returnValue: &retVal sendToTarget: target arguments: args];
    va_end(args);
    return retVal;
}

#define RT_ARG_MAGIC_COOKIE 0xdeadbeef
#pragma mark - private
- (void)_returnValue: (void *)retPtr sendToTarget: (id)target arguments: (va_list)args
{
    NSMethodSignature *signature = [target methodSignatureForSelector: [self selector]];
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature: signature];
    NSUInteger argumentCount = [signature numberOfArguments];

    [invocation setTarget: target];
    [invocation setSelector: [self selector]];
    for(NSUInteger i = 2; i < argumentCount; i++)
    {
        int cookie = va_arg(args, int);
        if(cookie != RT_ARG_MAGIC_COOKIE)
        {
            NSLog(@"%s: incorrect magic cookie %08x; did you forget to use RTARG() around your arguments?", __func__, cookie);
            abort();
        }
        const char *typeStr = va_arg(args, char *);
        void *argPtr = va_arg(args, void *);

        NSUInteger inSize;
        NSGetSizeAndAlignment(typeStr, &inSize, NULL);
        NSUInteger sigSize;
        NSGetSizeAndAlignment([signature getArgumentTypeAtIndex: i], &sigSize, NULL);

        if(inSize != sigSize)
        {
            NSLog(@"%s: size mismatch between passed-in argument and required argument; in type: %s (%lu) requested: %s (%lu)", __func__, typeStr, (long)inSize, [signature getArgumentTypeAtIndex: i], (long)sigSize);
            abort();
        }

        [invocation setArgument: argPtr atIndex: i];
    }

    [invocation invoke];

    if([signature methodReturnLength] && retPtr)
        [invocation getReturnValue: retPtr];
}

@end
