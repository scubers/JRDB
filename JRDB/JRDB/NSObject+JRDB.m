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


const NSString *JRDB_IDKEY = @"JRDB_IDKEY";

const NSString *jr_configureKey = @"jr_configureKey";

@implementation NSObject (JRDB)

+ (void)jr_configure {
    NSAssert(![objc_getAssociatedObject(self, _cmd) boolValue], @"This class's -[jr_configure] has been executed");
    
    // TODO: configure something
    
    objc_setAssociatedObject(self, _cmd, @(YES), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark - protocol method
- (void)setID:(NSString *)ID {
    objc_setAssociatedObject(self, &JRDB_IDKEY, ID, OBJC_ASSOCIATION_COPY_NONATOMIC);
}
- (NSString *)ID {
    return objc_getAssociatedObject(self, &JRDB_IDKEY);
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

- (BOOL)jr_objCanBeSave {
    if ([[self class] jr_primaryKey]) {
        return [self jr_primaryKeyValue];
    }
    return ![self ID];
}

#pragma mark - convinence method

- (void)jr_setSingleLinkID:(NSString *)ID forKey:(NSString *)key {
    objc_setAssociatedObject(self, NSSelectorFromString(SingleLinkColumn(key)), ID, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSString *)jr_singleLinkIDforKey:(NSString *)key {
    return objc_getAssociatedObject(self, NSSelectorFromString(SingleLinkColumn(key)));
}

#pragma mark - save

- (BOOL)jr_saveOnlyToDB:(FMDatabase *)db {
    return [db jr_saveOneOnly:self];
}
- (BOOL)jr_saveOnly {
    return [self jr_saveOnlyToDB:JR_DEFAULTDB];
}


- (BOOL)jr_saveUseTransaction:(BOOL)useTransaction toDB:(FMDatabase *)db {
    return [db jr_saveUseTransaction:useTransaction];
}
- (BOOL)jr_saveUseTransaction:(BOOL)useTransaction {
    return [self jr_saveUseTransaction:useTransaction toDB:JR_DEFAULTDB];
}

- (void)jr_saveUseTransaction:(BOOL)useTransaction complete:(JRDBComplete)complete toDB:(FMDatabase *)db {
    [db jr_saveOne:self useTransaction:useTransaction complete:complete];
}
- (void)jr_saveUseTransaction:(BOOL)useTransaction complete:(JRDBComplete)complete {
    [self jr_saveUseTransaction:useTransaction complete:complete toDB:JR_DEFAULTDB];
}


- (BOOL)jr_saveToDB:(FMDatabase *)db {
    return [db jr_saveOne:self useTransaction:YES];
}
- (BOOL)jr_save {
    return [self jr_saveToDB:JR_DEFAULTDB];
}

- (void)jr_saveWithComplete:(JRDBComplete)complete toDB:(FMDatabase *)db {
    [db jr_saveOne:self complete:complete];
}
- (void)jr_saveWithComplete:(JRDBComplete)complete {
    [self jr_saveWithComplete:complete toDB:JR_DEFAULTDB];
}

#pragma mark - update

- (BOOL)jr_updateOnlyColumns:(NSArray<NSString *> *)columns toDB:(FMDatabase *)db {
    return [db jr_updateOneOnly:self columns:columns];
}
- (BOOL)jr_updateOnlyColumns:(NSArray<NSString *> *)columns {
    return [self jr_updateOnlyColumns:columns toDB:JR_DEFAULTDB];
}

- (BOOL)jr_updateColumns:(NSArray<NSString *> *)columns useTransaction:(BOOL)useTransaction toDB:(FMDatabase *)db{
    return [db jr_updateOne:self columns:columns useTransaction:useTransaction];
}
- (BOOL)jr_updateColumns:(NSArray<NSString *> *)columns useTransaction:(BOOL)useTransaction {
    return [self jr_updateColumns:columns useTransaction:useTransaction toDB:JR_DEFAULTDB];
}

- (void)jr_updateColumns:(NSArray<NSString *> *)columns useTransaction:(BOOL)useTransaction complete:(JRDBComplete)complete toDB:(FMDatabase *)db{
    [db jr_updateOne:self columns:columns useTransaction:useTransaction complete:complete];
}
- (void)jr_updateColumns:(NSArray<NSString *> *)columns useTransaction:(BOOL)useTransaction complete:(JRDBComplete)complete {
    [self jr_updateColumns:columns useTransaction:useTransaction complete:complete toDB:JR_DEFAULTDB];
}

- (BOOL)jr_updateColumns:(NSArray<NSString *> *)columns toDB:(FMDatabase *)db{
    return [db jr_updateOne:self columns:columns];
}
- (BOOL)jr_updateColumns:(NSArray<NSString *> *)columns {
    return [self jr_updateColumns:columns toDB:JR_DEFAULTDB];
}

- (void)jr_updateColumns:(NSArray<NSString *> *)columns complete:(JRDBComplete)complete toDB:(FMDatabase *)db{
    [db jr_updateOne:self columns:columns complete:complete];
}
- (void)jr_updateColumns:(NSArray<NSString *> *)columns complete:(JRDBComplete)complete {
    [self jr_updateColumns:columns complete:complete toDB:JR_DEFAULTDB];
}


#pragma mark - delete

- (BOOL)jr_deleteOnlyFromDB:(FMDatabase *)db {
    return [db jr_deleteOneOnly:self];
}
- (BOOL)jr_deleteOnly {
    return [self jr_deleteOnlyFromDB:JR_DEFAULTDB];
}

- (BOOL)jr_deleteUseTransaction:(BOOL)useTransaction fromDB:(FMDatabase *)db {
    return [db jr_deleteOne:self useTransaction:useTransaction];
}
- (BOOL)jr_deleteUseTransaction:(BOOL)useTransaction {
    return [self jr_deleteUseTransaction:useTransaction fromDB:JR_DEFAULTDB];
}

- (void)jr_deleteUseTransaction:(BOOL)useTransaction complete:(JRDBComplete _Nullable)complete fromDB:(FMDatabase *)db{
    [db jr_deleteOne:self useTransaction:useTransaction complete:complete];
}
- (void)jr_deleteUseTransaction:(BOOL)useTransaction complete:(JRDBComplete _Nullable)complete {
    [self jr_deleteUseTransaction:useTransaction complete:complete fromDB:JR_DEFAULTDB];
}

- (BOOL)jr_deleteFromDB:(FMDatabase *)db {
    return [db jr_deleteOne:self];
}
- (BOOL)jr_delete {
    return [self jr_deleteFromDB:JR_DEFAULTDB];
}

- (void)jr_deleteWithComplete:(JRDBComplete _Nullable)complete fromDB:(FMDatabase *)db{
    [db jr_deleteOne:self complete:complete];
}
- (void)jr_deleteWithComplete:(JRDBComplete _Nullable)complete {
    [self jr_deleteWithComplete:complete fromDB:JR_DEFAULTDB];
}

#pragma mark - select

+ (instancetype _Nullable)jr_findByID:(NSString * _Nonnull)ID fromDB:(FMDatabase * _Nonnull)db {
    return (NSObject *)[db jr_findByID:ID clazz:self];
}

+ (instancetype _Nullable)jr_findByID:(NSString * _Nonnull)ID {
    return [self jr_findByID:ID fromDB:JR_DEFAULTDB];
}

+ (instancetype)jr_findByPrimaryKey:(id)primaryKey fromDB:(FMDatabase * _Nonnull)db {
    return (NSObject *)[db jr_findByPrimaryKey:primaryKey clazz:[self class]];
}
+ (instancetype)jr_findByPrimaryKey:(id)primaryKey {
    return [self jr_findByPrimaryKey:primaryKey fromDB:JR_DEFAULTDB];
}

+ (NSArray<id<JRPersistent>> *)jr_findAllFromDB:(FMDatabase *)db {
    return [db jr_findAll:[self class]];
}
+ (NSArray<id<JRPersistent>> *)jr_findAll {
    return [self jr_findAllFromDB:JR_DEFAULTDB];
}

+ (NSArray<id<JRPersistent>> *)jr_findAllFromDB:(FMDatabase *)db orderBy:(NSString *)orderBy isDesc:(BOOL)isDesc {
    return [db jr_findAll:[self class] orderBy:orderBy isDesc:isDesc];
}
+ (NSArray<id<JRPersistent>> *)jr_findAllOrderBy:(NSString *)orderBy isDesc:(BOOL)isDesc {
    return [self jr_findAllFromDB:JR_DEFAULTDB orderBy:orderBy isDesc:isDesc];
}

+ (NSArray<id<JRPersistent>> *)jr_findByConditions:(NSArray<JRQueryCondition *> *)conditions groupBy:(NSString *)groupBy orderBy:(NSString *)orderBy limit:(NSString *)limit isDesc:(BOOL)isDesc fromDB:(FMDatabase *)db {
    return [db jr_findByConditions:conditions clazz:[self class] groupBy:groupBy orderBy:orderBy limit:limit isDesc:isDesc];
}

+ (NSArray<id<JRPersistent>> *)jr_findByConditions:(NSArray<JRQueryCondition *> *)conditions groupBy:(NSString *)groupBy orderBy:(NSString *)orderBy limit:(NSString *)limit isDesc:(BOOL)isDesc {
    return [self jr_findByConditions:conditions groupBy:groupBy orderBy:orderBy limit:limit isDesc:isDesc fromDB:JR_DEFAULTDB];
}

#pragma mark - table message

+ (NSArray<NSString *> * _Nonnull)jr_currentColumnsInDB:(FMDatabase * _Nonnull)db {
    NSArray<JRColumnSchema *> * arr = [db jr_schemasInClazz:self];
    NSMutableArray *array = [NSMutableArray array];
    [arr enumerateObjectsUsingBlock:^(JRColumnSchema * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [array addObject:obj.name];
    }];
    return array;
}
+ (NSArray<NSString *> * _Nonnull)jr_currentColumns {
    return [self jr_currentColumnsInDB:JR_DEFAULTDB];
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

+ (BOOL)jr_executeUpdate:(NSString *)sql args:(NSArray *)args {
    return [self jr_executeUpdate:sql args:args fromDB:JR_DEFAULTDB];
}

+ (BOOL)jr_executeUpdate:(NSString *)sql args:(NSArray *)args fromDB:(FMDatabase *)db {
    return [db executeQuery:sql withArgumentsInArray:args];
}

#pragma mark - table operation

+ (BOOL)jr_createTableInDB:(FMDatabase *)db {
    return [db jr_createTable4Clazz:[self class]];
}

+ (BOOL)jr_createTable {
    return [self jr_createTableInDB:JR_DEFAULTDB];
}

+ (BOOL)jr_updateTableInDB:(FMDatabase *)db {
    return [db jr_updateTable4Clazz:[self class]];
}

+ (BOOL)jr_updateTable {
    return [self jr_updateTableInDB:JR_DEFAULTDB];
}

+ (BOOL)jr_dropTableInDB:(FMDatabase *)db {
    return [db jr_dropTable4Clazz:[self class]];
}

+ (BOOL)jr_dropTable {
    return [self jr_dropTableInDB:JR_DEFAULTDB];
}

+ (BOOL)jr_truncateTableInDB:(FMDatabase *)db {
    return [db jr_truncateTable4Clazz:[self class]];
}

+ (BOOL)jr_truncateTable {
    return [self jr_truncateTableInDB:JR_DEFAULTDB];
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
