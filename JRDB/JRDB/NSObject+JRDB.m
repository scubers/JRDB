//
//  NSObject+JRDB.m
//  JRDB
//
//  Created by JMacMini on 16/5/10.
//  Copyright © 2016年 Jrwong. All rights reserved.
//

#import "NSObject+JRDB.h"
#import <objc/runtime.h>
#import "FMDatabase+JRDB.h"
#import "JRDBMgr.h"
#import "JRFMDBResultSetHandler.h"
#import "JRReflectUtil.h"
#import "JRColumnSchema.h"
#import "JRDBChain.h"


static const NSString *JRDB_IDKEY                = @"JRDB_IDKEY";
static const NSString *jr_configureKey           = @"jr_configureKey";
static const NSString *jr_activatedPropertiesKey = @"jr_activatedPropertiesKey";

@implementation NSObject (JRDB)

+ (void)jr_configure {
    NSArray *activatedProp = [JRReflectUtil activitedProperties4Clazz:self];
    objc_setAssociatedObject(self, &jr_activatedPropertiesKey, activatedProp, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark - protocol method
- (void)setID:(NSString *)ID {
    objc_setAssociatedObject(self, &JRDB_IDKEY, ID, OBJC_ASSOCIATION_COPY_NONATOMIC);
}
- (NSString *)ID {
    return objc_getAssociatedObject(self, &JRDB_IDKEY);
}

- (BOOL)isCacheHit {
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

+ (NSArray *)jr_excludePropertyNames {
    return @[];
}

+ (NSDictionary<NSString *,Class<JRPersistent>> *)jr_singleLinkedPropertyNames {
    return nil;
}

+ (NSDictionary<NSString *,Class<JRPersistent>> *)jr_oneToManyLinkedPropertyNames {
    return nil;
}

+ (NSString *)jr_customPrimarykey {
    return nil;
}

- (id)jr_customPrimarykeyValue {
    return nil;
}

+ (NSString *)jr_primaryKey {
    if ([self jr_customPrimarykey]) {
        return [self jr_customPrimarykey];
    }
    return @"_ID";
}

- (id)jr_primaryKeyValue {
    if ([[self class] jr_customPrimarykey]) {
        return [self jr_customPrimarykeyValue];
    }
    return [self ID];
}

- (void)jr_addDidFinishBlock:(JRDBDidFinishBlock _Nullable)block forIdentifier:(NSString * _Nonnull)identifier; {
    [self jr_finishBlocks][identifier] = block;
}

- (void)jr_removeDidFinishBlockForIdentifier:(NSString *)identifier {
    [[self jr_finishBlocks] removeObjectForKey:identifier];
}

- (void)jr_executeFinishBlocks {
    __weak typeof(self) ws = self;
    [[self jr_finishBlocks] enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, JRDBDidFinishBlock  _Nonnull block, BOOL * _Nonnull stop) {
        block(ws);
    }];
}

- (NSMutableDictionary<NSString *,JRDBDidFinishBlock> *)jr_finishBlocks {
    NSMutableDictionary<NSString *,JRDBDidFinishBlock> *blocks = objc_getAssociatedObject(self, _cmd);
    if (!blocks) {
        blocks = [NSMutableDictionary dictionary];
        objc_setAssociatedObject(self, _cmd, blocks, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return blocks;
}

+ (NSArray<JRActivatedProperty *> *)jr_activatedProperties {
    return objc_getAssociatedObject(self, &jr_activatedPropertiesKey);
}

#pragma mark - convinence method

- (void)jr_setSingleLinkID:(NSString *)ID forKey:(NSString *)key {
    objc_setAssociatedObject(self, NSSelectorFromString(SingleLinkColumn(key)), ID, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSString *)jr_singleLinkIDforKey:(NSString *)key {
    return objc_getAssociatedObject(self, NSSelectorFromString(SingleLinkColumn(key)));
}

- (void)jr_setParentLinkID:(NSString *)ID forKey:(NSString *)key {
    objc_setAssociatedObject(self, NSSelectorFromString(ParentLinkColumn(key)), ID, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSString *)jr_parentLinkIDforKey:(NSString *)key {
    return objc_getAssociatedObject(self, NSSelectorFromString(ParentLinkColumn(key)));
}

#pragma mark - save or update

- (BOOL)jr_saveOrUpdateOnly {
    return J_SaveOrUpdate(self).UnRecursively.updateResult;
}

- (BOOL)jr_saveOrUpdate {
    return J_SaveOrUpdate(self).Recursively.updateResult;
}

#pragma mark - save

- (BOOL)jr_saveOnly {
    return J_Insert(self).updateResult;
}

- (BOOL)jr_save {
    return J_Insert(self).Recursively.updateResult;
}

#pragma mark - update

- (BOOL)jr_updateOnlyColumns:(NSArray<NSString *> *)columns {
    return J_Update(self).Columns(columns).updateResult;
}

- (BOOL)jr_updateColumns:(NSArray<NSString *> *)columns {
    return J_Update(self).Columns(columns).Recursively.updateResult;
}

- (BOOL)jr_updateOnlyIgnore:(NSArray<NSString *> *)Ignore {
    return J_Update(self).Ignore(Ignore).updateResult;
}

- (BOOL)jr_updateIgnore:(NSArray<NSString *> *)Ignore {
    return J_Update(self).Ignore(Ignore).updateResult;
}

#pragma mark - delete

+ (BOOL)jr_deleteAllOnly {
    return J_DeleteAll(self).updateResult;
}

+ (BOOL)jr_deleteAll {
    return J_DeleteAll(self).Recursively.updateResult;
}

- (BOOL)jr_deleteOnly {
    return J_Delete(self).updateResult;
}

- (BOOL)jr_delete {
    return J_Delete(self).Recursively.updateResult;
}

#pragma mark - select

+ (instancetype)jr_findByID:(NSString *)ID {
    return [JRDBChain new].Select(self).WhereIdIs(ID).Recursively.object;
}

+ (instancetype)jr_findByPrimaryKey:(id)primaryKey {
    return [JRDBChain new].Select(self).WherePKIs(primaryKey).Recursively.object;
}

+ (NSArray<id<JRPersistent>> *)jr_findAll {
    return [JRDBChain new].Select(self).Recursively.list;
}

+ (instancetype)jr_getByID:(NSString *)ID {
    return [JRDBChain new].Select(self).WhereIdIs(ID).object;
}

+ (instancetype)jr_getByPrimaryKey:(id)primaryKey {
    return [JRDBChain new].Select(self).WherePKIs(primaryKey).object;
}

+ (NSArray<id<JRPersistent>> *)jr_getAll {
    return [JRDBChain new].Select(self).list;
}

#pragma mark - table operation

+ (BOOL)jr_createTable {
    return J_CreateTable(self);
}

+ (BOOL)jr_updateTable {
    return J_UpdateTable(self);
}

+ (BOOL)jr_dropTable {
    return J_DropTable(self);
}

+ (BOOL)jr_truncateTable {
    return J_TruncateTable(self);
}

#pragma mark - table message

+ (NSArray<NSString *> * _Nonnull)jr_currentColumns {
    NSArray<JRColumnSchema *> * arr = [[JRDBMgr defaultDB] jr_schemasInClazz:self];
    NSMutableArray *array = [NSMutableArray array];
    [arr enumerateObjectsUsingBlock:^(JRColumnSchema * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [array addObject:obj.name];
    }];
    return array;
}

#pragma mark - method hook   now unavaliable  监听setter 由于swift 不适用，暂停使用
const static NSString *jr_changedArrayKey = @"jr_changedArrayKey";
- (NSMutableArray *)jr_changedArray {
    NSMutableArray *array = objc_getAssociatedObject(self, &jr_changedArrayKey);
    if (!array) {
        array = [NSMutableArray array];
        objc_setAssociatedObject(self, &jr_changedArrayKey, array, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return array;
}

+ (void)jr_swizzleSetters4Clazz {
    unsigned int outCount;
    Method *list = class_copyMethodList(self, &outCount);
    for (int i = 0; i < outCount; i++) {

        Method originMethod = list[i];
        SEL originSelector = method_getName(originMethod);
        NSString *methodName = [NSString stringWithUTF8String:sel_getName(originSelector)];

        NSString *paramterType = [self jr_type4SetterParameter:originSelector];
        if (paramterType && [methodName hasPrefix:@"set"]) {

            const char *typeEncoding = method_getTypeEncoding(originMethod);

            NSString *newMethodName = [NSString stringWithFormat:@"jr_%@", methodName];

            SEL newSelector = sel_registerName([newMethodName UTF8String]);
            IMP newImp = [self jr_swizzleImp4Selector:newSelector withTemplateSelector:originSelector];

            BOOL ret = class_addMethod(self, newSelector, newImp, typeEncoding);

            if (ret) {
                Method newMethod = class_getInstanceMethod(self, newSelector);
                method_exchangeImplementations(originMethod, newMethod);
            }
        }
    }
}

- (NSString *)jr_propertyNameWithSetter:(SEL)setter {

    NSString *setterName = [NSString stringWithUTF8String:sel_getName(setter)];
    if (![setterName hasPrefix:@"set"]) {
        return nil;
    }

    NSArray *ivarNames = [JRReflectUtil propNameAndEncode4Clazz:[self class]].allKeys;

    NSString *name = [setterName substringWithRange:NSMakeRange(3, setterName.length - 4)];
    NSString *first = [setterName substringWithRange:NSMakeRange(3, 1)].lowercaseString;
    name = [@"_" stringByAppendingString:[first stringByAppendingString:[name substringFromIndex:1]]];

    if ([ivarNames containsObject:name]) {
        return name;
    }
    name = [name substringFromIndex:1];
    if ([ivarNames containsObject:name]) {
        return name;
    }
    return nil;
}


#define IMPSomething(typeEncoding, jr_sel, jr_templateSel, jr_clazz, jr_type) \
if ([paramType isEqualToString:[NSString stringWithUTF8String:@encode(jr_type)]]) { \
imp = imp_implementationWithBlock(^(id target, jr_type value){ \
    NSLog(@"new method "); \
    NSLog(@"target: %@, value: %@ ", target, @(value)); \
    NSInvocation *inv = [NSInvocation invocationWithMethodSignature:[NSMethodSignature signatureWithObjCTypes:typeEncoding]]; \
    inv.target = target; \
    inv.selector = jr_sel; \
    [inv setArgument:&value atIndex:2]; \
    [inv invoke]; \
    NSString *propertyName = [((NSObject *)target) jr_propertyNameWithSetter:jr_templateSel]; \
    if (![((NSObject *)target).jr_changedArray containsObject:propertyName]) { \
        [((NSObject *)target).jr_changedArray addObject:propertyName]; \
    } \
}); \
}

#define ElseIMPSomething(typeEncoding, jr_sel, jr_templateSel, jr_clazz, jr_type) \
else IMPSomething(typeEncoding, jr_sel, jr_templateSel, jr_clazz, jr_type)

#define setMethod(name,type) \
- (void)jr__set##name:(type)a{}

//paramType
+ (IMP)jr_swizzleImp4Selector:(SEL)newSelector withTemplateSelector:(SEL)templeteSelector {

    IMP imp = nil;

    NSLog(@"%@", NSStringFromSelector(templeteSelector));

    const char *typeEncoding = method_getTypeEncoding(class_getInstanceMethod(self, templeteSelector));
    NSString *paramType = [self jr_type4SetterParameter:templeteSelector];

    IMPSomething(typeEncoding, newSelector, templeteSelector, self, int)
    ElseIMPSomething(typeEncoding, newSelector, templeteSelector, self, unsigned int)
    ElseIMPSomething(typeEncoding, newSelector, templeteSelector, self, long)
    ElseIMPSomething(typeEncoding, newSelector, templeteSelector, self, unsigned long)
    ElseIMPSomething(typeEncoding, newSelector, templeteSelector, self, double)
    ElseIMPSomething(typeEncoding, newSelector, templeteSelector, self, float)
    else
    {
        imp = imp_implementationWithBlock(^(id<NSObject> target, id value){

            NSLog(@"new method ");
            NSLog(@"target: %@, value: %@ ", target, value);

            NSInvocation *inv = [NSInvocation invocationWithMethodSignature:[NSMethodSignature signatureWithObjCTypes:typeEncoding]];
            inv.selector = newSelector;
            inv.target = target;
            [inv setArgument:&value atIndex:2];
            [inv invoke];

            NSString *propertyName = [((NSObject *)target) jr_propertyNameWithSetter:templeteSelector];
            if (![((NSObject *)target).jr_changedArray containsObject:propertyName]) {
                [((NSObject *)target).jr_changedArray addObject:propertyName];
            }

        });
    }
    return imp;
}

#define TypeEncodingEqual(sel, encoding) \
[[NSString stringWithUTF8String:encoding] isEqualToString:[NSString stringWithUTF8String:[JRReflectUtil typeEncoding4InstanceMethod:sel inClazz:[self class]]]]

+ (NSString *)jr_type4SetterParameter:(SEL)selector {
    const char *encoding = method_getTypeEncoding(class_getInstanceMethod(self, selector));

    if (TypeEncodingEqual(@selector(jr__setint:), encoding)) {
        return [NSString stringWithUTF8String:@encode(int)];
    }
    if (TypeEncodingEqual(@selector(jr__setunsignedInt:), encoding)) {
        return [NSString stringWithUTF8String:@encode(unsigned int)];
    }
    if (TypeEncodingEqual(@selector(jr__setlong:), encoding)) {
        return [NSString stringWithUTF8String:@encode(long)];
    }
    if (TypeEncodingEqual(@selector(jr__setunsignedLong:), encoding)) {
        return [NSString stringWithUTF8String:@encode(unsigned long)];
    }
    if (TypeEncodingEqual(@selector(jr__setdouble:), encoding)) {
        return [NSString stringWithUTF8String:@encode(double)];
    }
    if (TypeEncodingEqual(@selector(jr__setfloat:), encoding)) {
        return [NSString stringWithUTF8String:@encode(float)];
    }
    if (TypeEncodingEqual(@selector(jr__setid:), encoding)) {
        return [NSString stringWithUTF8String:@encode(id)];
    }
    return nil;
}

setMethod(int,int)
setMethod(unsignedInt,unsigned int)
setMethod(long,long)
setMethod(unsignedLong,unsigned long)
setMethod(double,double)
setMethod(float,float)
setMethod(id,id)


@end


