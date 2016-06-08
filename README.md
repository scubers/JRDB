# iOS用对FMDB的超好用封装

**一个对FMDB进行类Hibernate封装的ios库，支持Objective-C 和 Swift。**

[![Build Status](http://img.shields.io/travis/scubers/JRDB/developing.svg?style=flat)](https://travis-ci.org/scubers/JRDB)
[![Pod Version](http://img.shields.io/cocoapods/v/JRDB.svg?style=flat)](http://cocoadocs.org/docsets/JRDB/)
[![Pod Platform](http://img.shields.io/cocoapods/p/JRDB.svg?style=flat)](http://cocoadocs.org/docsets/JRDB/)
[![Pod License](http://img.shields.io/cocoapods/l/JRDB.svg?style=flat)](https://www.apache.org/licenses/LICENSE-2.0.html)


GitHub: [sucbers](https://github.com/scubers)

Feedback: [jr-wong@qq.com](mailto:jrwong@qq.com)

---

# Description

- 使用分类的模式，模仿Hibernate，对FMDB进行简易封装
- 支持pod 安装 『pod 'JRDB'』，Podfile需要添加  use_framework! 
- 使用协议，不用继承基类，对任意NSObject可以进行入库操作
- 支持swift 和 Objective-C
- 支持数据类型：基本数据类型（int，double，等），String，NSData，NSNumber，NSDate
  - 注：swift的基本数据类型，不支持**Option**类型，既不支持Int？Int！等，对象类型支持**Option**类型

---

# Installation 【安装】
```ruby
use_frameworks!
pod 'JRDB'
```

```objc
@import JRDB;
```

---

# Latest Update 【最新更新】

### Prepare 【准备】

* 相比之前版本，添加一步，所有需要操作入库的类都需要先注册一遍。

```objc
[[JRDBMgr shareInstance] registerClazzes:@[
                                           [Person class],
                                           [Card class],
                                           [Money class],
                                           ]];
```

* 每步的操作，实际都是根据数据转换成sql语句，可以设置是否打印

```objc
[JRDBMgr shareInstance].debugMode = NO;
```

### 关联操作 （保存）

* 一对一关联（model内含有model）；默认是不会进行关联保存的，若有需要关联保存，需要实现一下方法，并且子model也需要注册。

```objc
@interface Person : NSObject
@property (nonatomic, strong) Card *card;
@property (nonatomic, strong) NSMutableArray<Money *> *money;
@end

@implementation Person
+ (NSDictionary<NSString *,Class<JRPersistent>> *)jr_singleLinkedPropertyNames {
    return @{ @"_card" : [Card class]};
}
@end
```


* 一对多关联（model内含有model数组）；默认不会进行关联保存，若有需要关联保存，需要实现一下方法，并且子model也需要注册。

```objc
@interface Person : NSObject
@property (nonatomic, strong) Card *card;
@property (nonatomic, strong) NSMutableArray<Money *> *money;
@end

@implementation Person
+ (NSDictionary<NSString *,Class<JRPersistent>> *)jr_oneToManyLinkedPropertyNames {
    return @{ @"_money" : [Money class] };
}
@end
```

**注意：若子对象都是没有保存过的（既数据库没有的对象），则全部保存。若有已存在对象，不保存不更新。**

---

### 关联操作（更新）

* 出于更新的操作的随意性比较重，更新时不进行一切关联操作，即更新时，只更新本model相关信息，不更新所有子model的信息。当层级较多的时候，需要从子层级开始一步一步开始更新上来（所以不建议建立太多层级）

* 更新本model的信息包括：
   * 子model的ID会保存（若有）
   * 子model数组的数量（若子model数组数量发生变更会更新，但是子model的数组不会更到数据库）

---

### 关联操作（删除）
* 和更新一样，删除时，只会删除本model的信息，不会进行一切关联操作。
* 删除时，会删除一对多的中间表无用信息

---

### 关联操作（查询）
* jr\_get开头的查询操作，都不会进行关联操作，jr\_find开头的都会进行关联操作，当不需要关联查询的时候，使用get方法效率更高
	* jr\_find关联查询包括所有存在的一对一和一对多关联对象
	* jr\_get 得到的对象子对象都会是空的

---

### NSArray+JRDB
* 重写了NSObject+JRDB中的方法，可以批量 增删改查

```Objc
[array jr_save];
[[Person jr_findAll] jr_delete];
[[Card jr_findAll] jr_updateColumns:nil];
```

---
# Usage


### Save 【保存】
- OC

```Objc
Person *p = [[Person alloc] init];
p.a_int = 1;
p.b_unsigned_int = 2;
p.c_long = 3;
p.d_long_long = 4;
p.e_unsigned_long = 5;
p.f_unsigned_long_long = 6;
p.g_float = 7.0;
p.h_double = 8.0;
p.i_string = @"9";
p.j_number = @10;
p.k_data = [NSData data];
p.l_date = [NSDate date];
[p jr_save];
```

- **Swift**
	- Swift中需要入库的类需要继承**NSObject**（使用到runtime）
	- The Object that you want to persistent should inherit from **NSObject**

```swift
let p = Person()
p.name = "name"
p.age = 10
p.birthday = NSDate()
p.jr_save()
```

---

### Update 【更新】

```objc
Person *p = [Person jr_findAll].firstObject;
p.name = @"abc";
[p jr_updateColumns:nil];
```
	column: 需要更新的字段名，传入空为全量更新

---

### Delete 【删除】

```objc
Person *p = [Person jr_findAll].firstObject;
[p jr_delete];
```
---
###Select 【查找】

- 常规查找

```objc
Person *p = [Person jr_findByPrimaryKey:@"111"];
NSArray *list = [Person jr_findAll];
NSArray *list1 = [Person jr_findAllOrderBy:@"_age" isDesc:YES];
```

- 条件查询

```objc
NSArray *condis = @[
                    [JRQueryCondition condition:@"_l_date < ?" args:@[[NSDate date]] type:JRQueryConditionTypeAnd],
                    [JRQueryCondition condition:@"_a_int > ?" args:@[@9] type:JRQueryConditionTypeAnd],
                    ];
    
NSArray *arr = [Person jr_findByConditions:condis
                                   groupBy:@"_room"
                                   orderBy:@"_age"
                                     limit:@" limit 0,13 "
                                    isDesc:YES];
```

- SQL

```objc
NSString *sql = @"select * from Person where age = ?";
NSArray *list = [Person jr_executeSql:sql args:@[@10]];
```
---

# Other 【其他】

### 协议：JRPersistent

```objc
@protocol JRPersistent <NSObject>
@required
- (void)setID:(NSString * _Nullable)ID;
- (NSString * _Nullable)ID;
@optional
/**
 *  返回不用入库的对象字段数组
 *  The full property names that you want to ignore for persistent
 *  @return array
 */
+ (NSArray * _Nullable)jr_excludePropertyNames;
/**
 *  返回自定义主键字段
 *  @return 字段全名
 */
+ (NSString * _Nullable)jr_customPrimarykey;
/**
 *  返回自定义主键值
 *  @return 主键值
 */
- (id _Nullable)jr_customPrimarykeyValue;
@end
```

### 主键
默认每个Object的主键为ID， UUID字符串。

可以实现 `jr_customPrimarykey` 以及 `jr_customPrimarykeyValue ` 方法，自定义主键。

### 默认NSObject分类实现

```objc
@interface NSObject (JRDB) <JRPersistent>
(...methods)
@end
```

--
### JRDBMgr

```objc
@interface JRDBMgr : NSObject

@property (nonatomic, strong) FMDatabase * _Nullable defaultDB;
@property (nonatomic, assign) BOOL debugMode;

+ (instancetype _Nonnull)shareInstance;
+ (FMDatabase * _Nonnull)defaultDB;
- (FMDatabase * _Nullable)createDBWithPath:(NSString * _Nullable)path;
- (void)deleteDBWithPath:(NSString * _Nullable)path;

/**
 *  在这里注册的类，使用本框架的只能操作已注册的类
 *  @param clazz 类名
 */
- (void)registerClazz:(Class<JRPersistent> _Nonnull)clazz;
- (void)registerClazzes:(NSArray<Class<JRPersistent>> * _Nonnull)clazzArray;
- (NSArray<Class> * _Nonnull)registeredClazz;

/**
 * 更新默认数据库的表（或者新建没有的表）
 * 更新的表需要在本类先注册
 */
- (void)updateDefaultDB;
- (void)updateDB:(FMDatabase * _Nonnull)db;


/**
 *  检查是否注册
 *
 *  @param clazz 类
 *  @return 结果
 */
- (BOOL)isValidateClazz:(Class<JRPersistent> _Nonnull)clazz;

/**
 *  清理中间表的缓存辣鸡
 *
 *  @param db
 */
- (void)clearMidTableRubbishDataForDB:(FMDatabase * _Nonnull)db;
```

JRDBMgr持有一个默认数据库（~/Documents/jrdb/jrdb.sqlite），任何不指定数据库的操作，都在此数据库进行操作。默认数据库可以自行设置。

---

# Table Operation 【表操作】

### Create 【建表】
```objc
// FMDatabase+JRDB 方法
[[JRDBMgr defaultDB] createTable4Clazz:[Person class]];
[Person jr_createTable];

// 删除原有的表，重新创建
[[JRDBMgr defaultDB] truncateTable4Clazz:[Person class]];
[Person jr_truncateTable];

//保存时，若发现没有表，将自动创建
[person jr_save];
```
### Update 【更新表】

```objc
[[JRDBMgr defaultDB] updateTable4Clazz:[Person class]];
[Person jr_updateTable];
```
更新表时，只会添加不存在的字段，不会修改字段属性，不会删除字段，若有需要，需要自行写sql语句进行修改
### Drop 【删表】
```objc
[[JRDBMgr defaultDB] dropTable4Clazz:[Person class]];
[Person jr_dropTable];
```
---

# Thread Operation 【线程操作】
- 多线程操作使用FMDB自带的 FMDatabaseQueue

```objc
[person jr_saveWithComplete:^(BOOL success) {
    NSLog(@"%d", success);
}];

```
任何带complete block的操作，都将放入到FMDatabaseQueue进行顺序执行

- 注：所有需要立刻返回结果，或者影响其他操作的数据库操作，都建议放在主线程进行更新，大批量更新以及多线程操作数据库时，请使用带complete block的操作。


---

# MoreUsage
- 查看FMDatabase+JRDB.h

### Other
库还在更新中，如果有使用不好或者bug，请邮件联系
