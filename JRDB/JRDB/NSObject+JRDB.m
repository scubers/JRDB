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

#define JR_DEFAULTDB [JRDBMgr defaultDB]

const NSString *JRDB_IDKEY = @"JRDB_IDKEY";

@implementation NSObject (JRDB)

- (void)setID:(NSString *)ID {
    objc_setAssociatedObject(self, &JRDB_IDKEY, ID, OBJC_ASSOCIATION_COPY_NONATOMIC);
}
- (NSString *)ID {
    return objc_getAssociatedObject(self, &JRDB_IDKEY);
}
+ (NSArray *)jr_excludePropertyNames {
    return @[];
}

+ (NSDictionary *)jr_mapPropNames {
    return @{};
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


#pragma mark - save
- (BOOL)jr_saveToDB:(FMDatabase *)db {
    return [db saveObj:self];
}

- (void)jr_saveToDB:(FMDatabase *)db complete:(JRDBComplete)complete {
    [db saveObj:self complete:^(BOOL success) {
        EXE_BLOCK(complete, success);
    }];
}

- (BOOL)jr_save {
    return [self jr_saveToDB:JR_DEFAULTDB];
}

- (void)jr_saveWithComplete:(JRDBComplete)complete {
    [self jr_saveToDB:JR_DEFAULTDB complete:complete];
}

#pragma mark - update
- (BOOL)jr_updateToDB:(FMDatabase *)db column:(NSArray *)columns {
    return [db updateObj:self columns:columns];
}
- (void)jr_updateToDB:(FMDatabase *)db column:(NSArray *)columns complete:(JRDBComplete)complete {
    [db updateObj:self columns:columns complete:^(BOOL success) {
        EXE_BLOCK(complete, success);
    }];
}

- (BOOL)jr_updateWithColumn:(NSArray *)columns {
    return [self jr_updateToDB:JR_DEFAULTDB column:columns];
}

- (void)jr_updateWithColumn:(NSArray *)columns Complete:(JRDBComplete)complete {
    [self jr_updateToDB:JR_DEFAULTDB column:columns complete:complete];
}

#pragma mark - delete

- (BOOL)jr_deleteFromDB:(FMDatabase *)db {
    return [db deleteObj:self];
}

- (void)jr_deleteFromDB:(FMDatabase *)db complete:(JRDBComplete)complete {
    [db deleteObj:self complete:^(BOOL success) {
        EXE_BLOCK(complete, success);
    }];
}

- (BOOL)jr_delete {
    return [self jr_deleteFromDB:JR_DEFAULTDB];
}

- (void)jr_deleteWithComplete:(JRDBComplete)complete {
    [self jr_deleteFromDB:JR_DEFAULTDB complete:complete];
}

#pragma mark - select

+ (instancetype)jr_findByPrimaryKey:(id)ID fromDB:(FMDatabase * _Nonnull)db {
    return [db findByPrimaryKey:ID clazz:[self class]];
}
+ (instancetype)jr_findByPrimaryKey:(id)ID {
    return [self jr_findByPrimaryKey:ID fromDB:JR_DEFAULTDB];
}

+ (NSArray<id<JRPersistent>> *)jr_findAllFromDB:(FMDatabase *)db {
    return [db findAll:[self class]];
}
+ (NSArray<id<JRPersistent>> *)jr_findAll {
    return [self jr_findAllFromDB:JR_DEFAULTDB];
}

+ (NSArray<id<JRPersistent>> *)jr_findAllFromDB:(FMDatabase *)db orderBy:(NSString *)orderBy isDesc:(BOOL)isDesc {
    return [db findAll:[self class] orderBy:orderBy isDesc:isDesc];
}
+ (NSArray<id<JRPersistent>> *)jr_findAllOrderBy:(NSString *)orderBy isDesc:(BOOL)isDesc {
    return [self jr_findAllFromDB:JR_DEFAULTDB orderBy:orderBy isDesc:isDesc];
}

+ (NSArray<id<JRPersistent>> *)jr_findByConditions:(NSArray<JRQueryCondition *> *)conditions groupBy:(NSString *)groupBy orderBy:(NSString *)orderBy limit:(NSString *)limit isDesc:(BOOL)isDesc fromDB:(FMDatabase *)db {
    return [db findByConditions:conditions clazz:[self class] groupBy:groupBy orderBy:orderBy limit:limit isDesc:isDesc];
}

+ (NSArray<id<JRPersistent>> *)jr_findByConditions:(NSArray<JRQueryCondition *> *)conditions groupBy:(NSString *)groupBy orderBy:(NSString *)orderBy limit:(NSString *)limit isDesc:(BOOL)isDesc {
    return [self jr_findByConditions:conditions groupBy:groupBy orderBy:orderBy limit:limit isDesc:isDesc fromDB:JR_DEFAULTDB];
}

#pragma mark - sql
+ (NSArray<id<JRPersistent>> *)jr_executeSql:(NSString *)sql args:(NSArray *)args fromDB:(FMDatabase *)db {
    FMResultSet *ret = [db executeQuery:sql withArgumentsInArray:args];
    return [JRFMDBResultSetHandler handleResultSet:ret forClazz:[self class]];
}

+ (NSArray<id<JRPersistent>> *)jr_executeSql:(NSString *)sql args:(NSArray *)args {
    return [self jr_executeSql:sql args:args fromDB:JR_DEFAULTDB];
}

+ (NSUInteger)jr_countForSql:(NSString *)sql args:(NSArray *)args fromDB:(FMDatabase *)db {
    FMResultSet *ret = [db executeQuery:sql withArgumentsInArray:args];
    return (NSUInteger)[ret unsignedLongLongIntForColumnIndex:0];
}

+ (NSUInteger)jr_countForSql:(NSString *)sql args:(NSArray *)args {
    return [self jr_countForSql:sql args:args fromDB:JR_DEFAULTDB];
}

#pragma mark - table operation

+ (BOOL)jr_createTableInDB:(FMDatabase *)db {
    return [db createTable4Clazz:[self class]];
}

+ (BOOL)jr_createTable {
    return [self jr_createTableInDB:JR_DEFAULTDB];
}

+ (BOOL)jr_updateTableInDB:(FMDatabase *)db {
    return [db updateTable4Clazz:[self class]];
}

+ (BOOL)jr_updateTable {
    return [self jr_updateTableInDB:JR_DEFAULTDB];
}

+ (BOOL)jr_dropTableInDB:(FMDatabase *)db {
    return [db dropTable4Clazz:[self class]];
}

+ (BOOL)jr_dropTable {
    return [self jr_dropTableInDB:JR_DEFAULTDB];
}

+ (BOOL)jr_truncateTableInDB:(FMDatabase *)db {
    return [db truncateTable4Clazz:[self class]];
}

+ (BOOL)jr_truncateTable {
    return [self jr_truncateTableInDB:JR_DEFAULTDB];
}

#pragma mark - method hook
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

    NSArray *ivarNames = [JRReflectUtil ivarAndEncode4Clazz:[self class]].allKeys;

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
