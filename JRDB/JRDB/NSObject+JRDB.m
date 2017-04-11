//
//  NSObject+JRDB.m
//  JRDB
//
//  Created by JMacMini on 16/5/10.
//  Copyright © 2016年 Jrwong. All rights reserved.
//

#import "NSObject+JRDB.h"
#import <objc/runtime.h>
#import "JRDBMgr.h"
#import "JRFMDBResultSetHandler.h"
#import "JRDBChain.h"
#import "JRPersistentUtil.h"

@implementation NSObject (JRPersistent)

#pragma mark - protocol method

- (void)setID:(NSString *)ID {
    objc_setAssociatedObject(self, @selector(setID:), ID, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSString *)ID {
    return objc_getAssociatedObject(self, @selector(setID:));
}

+ (void)setRegistered:(BOOL)registered {
    objc_setAssociatedObject(self, @selector(setRegistered:), @(registered), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

+ (BOOL)isRegistered {
    return [objc_getAssociatedObject(self, @selector(setRegistered:)) boolValue];
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

+ (NSString *)jr_customTableName {
    return nil;
}

+ (NSDictionary<NSString *,NSString *> *)jr_databaseNameMap {
    return @{};
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


#pragma mark convenience method

+ (NSString *)jr_tableName {
    return [self jr_customTableName]?:[self shortClazzName];
}

+ (NSString *)jr_primaryKey {
    if ([self jr_customPrimarykey]) {
        return [self jr_customPrimarykey];
    }
    return DBIDKey;
}

- (id)jr_primaryKeyValue {
    if ([[self class] jr_customPrimarykey]) {
        return [self jr_customPrimarykeyValue];
    }
    return [self ID];
}


@end

/****************************************************************/


@implementation NSObject (JRDB)

+ (void)jr_configure {
    NSArray *activatedProp = [JRPersistentUtil allPropertesForClass:self];
    objc_setAssociatedObject(self, @selector(jr_activatedProperties), activatedProp, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}


+ (NSArray<JRActivatedProperty *> *)jr_activatedProperties {
    return objc_getAssociatedObject(self, _cmd);
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



@end


