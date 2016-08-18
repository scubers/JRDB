# iOS用对FMDB封装

**一个对FMDB进行类Hibernate封装的ios库**

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

# Installation
```
pod 'JRDB'
```

# Latest Update

> - 优化线程操作
> - 修复一直bug
> - 完善测试用例（完善测试代码覆盖率）
> - 优化代码，去除宏代码编写


---

# API链式调用

Insert
---

```objc

Person *p = [Person new];

BOOL result = J_Insert(p)
					.InDB([JRDBMgr defaultDB]) // by Default 
					.Recursive(NO)			// by default 
					.Sync(YES)				// by default
					.Trasaction(YES)			// by default
					.updateResult;		

// 可以省略为
BOOL result = J_Insert(p).updateResult;
		
// 数组保存，两种 api 自由使用
BOOL result = J_Insert(p1, p2, p3).updateResult;

BOOL result = J_Insert(@[p1, p2, p3]).updateResult;

```


Update
---

```objc
// 更新指定列
BOOL result = J_Update(p).Columns(@[@"_age", @"_name"]).updateResult;
// 忽略指定列
BOOL result = J_Update(p).Ignore(@[@"_phone"]).updateResult;

// 更新数组
BOOL result = J_Update(p1, p2).updateResult;
BOOL result = J_Update(@[p1, p2, p3]).updateResult;
```


Delete
---

* 相关配置（Insert 和 Update的配置都可以使用）
* Recursive：[详细请看](#linkdelete)

```objc
BOOL result = J_Delete(p).updateResult;
```


Select
---


```objc
// 普通查询
NSArray *result = J_Select(Person)
                    .Recursive(YES)		// by default
                    .Sync(YES)			// by default
                    .Cache(NO)			// by default
                    .Desc(NO)				// by default
                    .Where(@"_name like ? and _height > ?")
                    .Params(@[@"L%", @150])
                    .Group(@"_level")
                    .Order(@"_age")
                    .Limit(0, 10)			
                    .list;

// 自定义查询
NSArray *result = J_SelectColumns(@[@"_age", @"_name"])
						.FromJ([Person class])
						.Recursive(YES)   // this will not function in customize query
						.Sync(YES)		 // by default
						.Cache(NO)		 // this will not function in customize query
						.Where(@"_name like ? and _height > ?")
						.Params(@[@"L%", @150])
						.Group(@"_level")
						.Order(@"_age")
						.Limit(0, 10)
						.Desc(NO)			// by default
						.list;

NSUInteger count = J_SelectCount(Person)
						.Recursive(YES)   // this will not function in customize 
						.Sync(YES)
						.Cache(NO)		 // this will not function in customize 
						.Where(@"_name like ? and _height > ?")
						.Params(@"L%", @150)
						.Group(@"_level")
						.Order(@"_age")
						.Limit(0, 10)
						.Desc(YES) 
						.count;
                    
```
  
- Configuration

| 配置        	| 功能		|参数类型| 
|:-------------:|------------| -------- |
| InDB		| [JRDBMgr defaultDB] by default;|FMDatabase * |
| From		| 自定义查询时指定的类名|Class |
| Recursive		| NO by default;<br/> NO:效率高，<br/>YES：[关联操作](#linksave)效率低|YES or NO|
| Transaction		| YES by default;<br/> NO:本操作不包含事务，外界需要事务支持<br/>YES：包含事务|YES or NO|
| Sync     		| YES by default;<br/>YES:阻塞本线程，线程安全同步执行数据库操作；<br/>NO：在本线程执行数据库操作，线程不安全	|YES or NO|
| Cache		| NO by default	|YES or NO|
| Where		| Where 后面的条件筛选语句，使用 ？作为参数占位符| NSString * |
| WhereIdIs	| 等同于 Where(@" _id = ?")| NSString * |
| WherePKIs	| 等同于 Where(@"<#primary key#> = ?")| id |
| Params		| Where 语句占位符对应的参数| NSArray * | 
| Columns		| 更新时候指定更新的列| NSArray * | 
| Ignore		| 更新时指定忽略的列| NSArray * | 
| Group		| group by 字段| NSString * |
| Order		| order by 字段| NSString * |
| Limit		| 分页字段 （start, length）| unsigned long, unsigned long |
| Desc			| NO by default; 是否根据orderby 进行降序 | YES or NO|


Macro
---

- 使用宏，让调用变成更智能
 	- `From([Person class]) --> FromJ(Person)`
	- `Where(@"_name = ?") --> WhereJ(_name = ?)`
	- `Order(@"_name") --> OrderJ(name)`
	- `Group(@"_name") --> GroupJ(name)`
	- `Params(@[@"jack", @"mark"]) --> ParamsJ(@"jack", @"mark")`
	- `Ignore(@[@"_name", @"_age"]) --> IgnoreJ(@"_name", @"_age")`
	- `Columns(@[@"_name", @"_age"]) --> ColumnsJ(@"_name", @"_age")`
	
```
// example
NSArray *result = J_Select(Person)
                    .WhereJ(_name like ? and _height > ?)
                    .ParamsJ(@"a%", @100)
                    .GroupJ(h_double)
                    .OrderJ(d_long_long)
                    .list;
                    
BOOL result = J_Update(person)
						.ColumnsJ(J(name), J(age))
					//	.IgnoreJ(J(name), J(age))
                    .updateResult;
```


# --------------------Old Version---------------------

#### NSObject+JRDB

使用JRDBChain重构NSObject+JRDB类 重新定义该分类的功能。

- 重构，简化API，使用更简单。
- 该分类的所有方法都是同步方法，线程安全，并且阻塞本线程执行。
- 该分类中的方法全部使用事务。
- 该分类方法不能在	`FMDatabase+JRDB.h` 中的各种block中使用，因为分类中的方法使用的是默认数据库，而  `FMDatabase+JRDB.h` 中的block都要使用回调block中提供的 `FMDatabase` 对象。


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

<a id='linksave'></a>
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

<a id='linkupdate'></a>
### 关联操作（更新）

* 出于更新的操作的随意性比较重，更新时不进行一切关联操作，即更新时，只更新本model相关信息，不更新所有子model的信息。当层级较多的时候，需要从子层级开始一步一步开始更新上来（所以不建议建立太多层级）

* 更新本model的信息包括：
   * 子model的ID会保存（若有）
   * 子model数组的数量（若子model数组数量发生变更会更新，但是子model的数组不会更到数据库）

---

<a id='linkdelete'></a>
### 关联操作（删除）
* 和更新一样，删除时，只会删除本model的信息，不会进行一切关联操作。
* 删除时，会删除一对多的中间表无用信息

---

<a id='linkselect'></a>
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
