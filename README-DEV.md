# iOS用对FMDB的超好用封装

**一个对FMDB进行类Hibernate封装的ios库

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

## 1.0.0更新内容
- 简化API数量，提高方法灵活度
- 添加连接调用，查询更方便，摆脱JRQueryCondition的困扰
- 新增查询缓存，可配置是否使用缓存，提高查询速度
- 更灵活的线程调用
- 修复已知bug


## API链式调用

---

#### Insert【插入】

```objc

// 链式调用统一返回 id 类型，update数据库返回是 @YES 或者 @NO
Person *p = [Person new];

id result =[J_Insert(p)
				.InDB([JRDBMgr defaultDB])  
				.Recursive(YES) 		
				.Sync(YES)			
				.Trasaction(YES)		
				exe:nil];		

// 可以省略为
id result = [J_Insert(p) exe:nil];
		
// 数组保存，两种 api 自由使用
id result = [J_Insert(p1, p2, p3) exe:nil]

id result = [J_Insert(@[p1, p2, p3]) exe:nil]

```

- 相关配置

| 配置        	| 功能		|参数类型|
|:-------------:|------------| --------|
| InDB				| 配置可以省略，默认使用[JRDBMgr defaultDB]，执行的数据库| InDB(FMDatabase *)|
| Recursive     | 配置可以省略，默认为NO，功能为开关是否进行[关联操作](#linksave)|YES or NO|
| Sync				|配置可以省略，默认YES：阻塞本线程，线程安全同步执行数据库操作，使用FMDatabaseQueue；NO：在本线程执行数据库操作，线程不安全，使用FMDatabase|YES or NO|
|Transaction		|配置可省略，默认为YES：本操作自带事务；NO：本操作不开启事务，需要外部有事务支持|YES or NO|
|exe:nil|执行数据库操作，参数为数据库操作完成的回调block|block or nil|

---

#### Update【更新】

```objc

// 更新指定列
id result = [J_Update(p)
                 .ColumnsJ(@"_age", @"_name")
               //.Columns(@[@"_age", @"_name"])
                  exe:nil];
// 忽略指定列
id result = [J_Update(p)
                 .IgnoreJ(@"_phone")
               //.Ignore(@[@"_phone"])
                  exe:nil];

// 更新数组
id result = [J_Update(p1, p2) exe:nil];
id result = [J_Update(@[p1, p2, p3]) exe:nil];
```

- 相关配置

| 配置        	| 功能		|参数类型|
|:-------------:|------------| ----- |
| Columns			| 配置可省略，默认为nil，更新时的指定列| NSArray *|
| Ignore     		| 配置可省略，默认为nil，更新时的忽略指定列| NSArray * |
| Recursive		| 更新的关联操作[详情请看](#linkupdate)| YES or NO |
||可以使用Insert的配置	|

---

#### Delete【删除】
* 相关配置（Insert 和 Update的配置都可以使用）
* Recursive：[详细请看](#linkdelete)

```objc
id result = [J_Delete(p) exe:nil];
```

---

#### Select 【查询】


```objc
// 普通查询
id result = [J_Select([Person class])
                    .Recursive(YES)
                    .Sync(YES)
                    .Cache(YES)
                    .Where(@"_name like ? and _height > ?")
                    .Params(@[@"L%", @150])
                    .Group(@"_level")
                    .Order(@"_age")
                    .Limit(0, 10)
                    .Desc(YES)
                    exe:nil];

id result = [J_Select(nil)
					.From([Person class]) 
					.Recursive(YES)
					.Sync(YES)
					.Cache(YES)
					.Where(@"_name like ? and _height > ?")
					.Params(@[@"L%", @150])
					.Group(@"_level")
					.Order(@"_age")
					.Limit(0, 10)
					.Desc(YES) 
					exe:nil];

// 自定义查询
//id result = [J_Select(@"_age", @"_name")
id result = [J_Select(@[@"_age", @"_name"])
						.From([Person class])
						.Recursive(YES)   // 自定义查询的时候，不会进行关联查询
						.Sync(YES)
						.Cache(YES)
						.Where(@"_name like ? and _height > ?")
						.Params(@[@"L%", @150])
						.Group(@"_level")
						.Order(@"_age")
						.Limit(0, 10)
						.Desc(YES)
						exe:nil];

id result = [J_Select(JRCount)
						.From([Person class])
						.Recursive(YES)   // 自定义查询的时候，不会进行关联查询
						.Sync(YES)
						.Cache(YES)
						.Where(@"_name like ? and _height > ?")
						.Params(@"L%", @150)
						.Group(@"_level")
						.Order(@"_age")
						.Limit(0, 10)
						.Desc(YES) 
						exe:nil];			
                    
```

- 相关配置

| 配置        	| 功能		|参数类型|
|:-------------:|------------| -------- |
| Recursive		| 配置可省略，默认为NO: 不进行[关联查询](#linkselect)效率高，YES：[关联查询](#linkselect)效率低|YES or NO|
| Sync     		| 配置可以省略，默认YES：阻塞本线程，线程安全同步执行数据库操作；NO：在本线程执行数据库操作，线程不安全|YES or NO|
| Cache		| 配置可省略，默认为NO: 不使用缓存；YES：使用缓存|YES or NO|
| Where		| Where 后面的条件筛选语句，使用 ？作为参数占位符| NSString * |
| Params		| Where 语句占位符对应的参数| NSArray * | 
| Group		| group by 字段| NSString * |
| Order		| order by 字段| NSString * |
| limit		| 分页字段 （start, length）| unsigned long, unsigned long |
| Desc			| 是否倒序，默认NO | YES or NO|

---

#### 宏

在写链式调用的时候，每次写字符串都要写个 @""，实在太烦人，囧，懒惰的我，你懂的

```objc

#define J_Select(...)           ([JRDBChain new].Select((_variableListToArray(__VA_ARGS__, 0))))
#define J_SelectJ(_arg_)        (J_Select([_arg_ class]))

#define J_Insert(...)           ([JRDBChain new].Insert(_variableListToArray(__VA_ARGS__, 0)))
#define J_Update(...)           ([JRDBChain new].Update(_variableListToArray(__VA_ARGS__, 0)))
#define J_Delete(...)           ([JRDBChain new].Delete(_variableListToArray(__VA_ARGS__, 0)))
#define J_SaveOrUpdate(...)     ([JRDBChain new].SaveOrUpdate(_variableListToArray(__VA_ARGS__, 0)))

#define J_DeleteAll(_arg_)      ([JRDBChain new].DeleteAll([_arg_ class]))

#define J_CreateTable(_arg_)    ([JRDBChain new].CreateTable([_arg_ class]))
#define J_UpdateTable(_arg_)    ([JRDBChain new].UpdateTable([_arg_ class]))
#define J_DropTable(_arg_)      ([JRDBChain new].DropTable([_arg_ class]))
#define J_TruncateTable(_arg_)  ([JRDBChain new].TruncateTable([_arg_ class]))

#define ParamsJ(...)            Params((_variableListToArray(__VA_ARGS__, 0)))
#define ColumnsJ(...)           Columns((_variableListToArray(__VA_ARGS__, 0)))
#define IgnoreJ(...)            Ignore((_variableListToArray(__VA_ARGS__, 0)))

#define FromJ(_arg_)            From([_arg_ class])
#define WhereJ(_arg_)           Where(@#_arg_)
#define OrderJ(_arg_)           Order(@#_arg_)
#define GroupJ(_arg_)           Group(@#_arg_)


```

有了上面的宏，调用就可以下面这样的

```objc

//id result = [J_Select(nil)
//                .FromJ(Person)
id result = [J_SelectJ(Person)
                .Recursive(YES)
                .Sync(YES)
                .Cache(YES)
                .WhereJ(_name like ? and _height > ?)
                .Params(@"a%", @100)
                .GroupJ(_level)
                .OrderJ(_age)
                .Limit(0, 10)
                .Desc(YES)
                exe:nil];

// 自定义查询
//id result = [J_Select(@"_age", @"_name")
id result = [J_Select(@[@"_age", @"_name"])
						.FromJ(Person)
						.Recursive(YES)   // 自定义查询的时候，不会进行关联查询
						.Sync(YES)
						.Cache(YES)
						.WhereJ(_name like ? and _height > ?)
						.ParamsJ(@"L%", @150)
						.GroupJ(_level)
						.OrderJ(_age)
						.Limit(0, 10)
						.Desc(YES)
						exe:nil];

```

| 配置        	| 使用类型|
|:-------------:|------------|
| `J_Select`		| `J_Select([Person class])`, `J_Select(nil)`, `J_Select(@[@"_name", @"_age"])`|
| `J_SelectJ`		| `J_Select(Person)`|
| `J_Insert`		| `J_Insert(p1, p2, p3)`, `J_Insert(@[p1, p2, p3])` update，delete， saveOrUpdate 同理|
| `J_DeleteAll`	| `J_DeleteAll(Person)`, CreateTable, UpdateTable, DropTable, TruncateTable 同理|
| `ParamsJ`		| `ParamsJ(@1, @3, @4)`, `Params(@[@1, @3, @4])`, ColumnsJ, IgnoreJ, 同理 |
| `FromJ`			| `FromJ(Person)`, WhereJ, OrderJ, GroupJ, 同理 |

#### NSObject+JRDB

使用JRDBChain重构NSObject+JRDB类 重新定义该分类的功能。

- 重构，简化API，使用更简单。
- 该分类的所有方法都是同步方法，线程安全，并且阻塞本线程执行。
- 该分类中的方法全部使用事务。
- 该分类方法不能在	`FMDatabase+JRDB.h` 中的各种block中使用，因为分类中的方法使用的是默认数据库，而  `FMDatabase+JRDB.h` 中的block都要使用回调block中提供的 `FMDatabase` 对象。

 

---

# ----------旧版更新  Old Version-----------

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
