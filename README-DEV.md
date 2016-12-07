# iOS用对FMDB封装

**一个对FMDB进行类Hibernate封装的ios库**

[![Build Status](http://img.shields.io/travis/scubers/JRDB/developing.svg?style=flat)](https://travis-ci.org/scubers/JRDB)
[![Pod Version](http://img.shields.io/cocoapods/v/JRDB.svg?style=flat)](http://cocoadocs.org/docsets/JRDB/)
[![Pod Platform](http://img.shields.io/cocoapods/p/JRDB.svg?style=flat)](http://cocoadocs.org/docsets/JRDB/)
[![Pod License](http://img.shields.io/cocoapods/l/JRDB.svg?style=flat)](https://www.apache.org/licenses/LICENSE-2.0.html)


GitHub: [sucbers](https://github.com/scubers)

Feedback: [jr-wong@qq.com](mailto:jrwong@qq.com)

有问题或者bug欢迎随时issues我，或者邮件。感谢使用

---

# 描述（Description）

> - 使用分类的模式，模仿Hibernate，对FMDB进行简易封装 
> - 使用协议，不用继承基类，对任意NSObject可以进行入库操作
> - Objective-C（Swift 请移步 [Swift扩展](https://github.com/scubers/JRDBSwift)）

> ~~支持数据类型：基本数据类型（int，double，等），String，NSData，NSNumber，NSDate~~

> ~~注：swift的基本数据类型，不支持**Option**类型，既不支持Int？Int！等，对象类型支持**Option**类型~~

---

# 目录（Index）
- [安装](#installationId) 
- [表操作](#tableId)  
- [保存](#saveId)
- [更新](#updateId)
- [删除](#deleteId)  
- [查询](#queryId)  
- [链式调用配置](#configurationId) 
- [关联操作](#linkId)  
- [宏](#macroId)   
- [子查询](#subQueryId) 
- [线程安全](#threadId) 

<a id="installationId"></a>
# 安装（Installation）
```
pod 'JRDB'
```

---

<a id="startId"></a>
# 开始（Start）

## 注册
- 需要使用本库的类都需要注册。

```objc
[[JRDBMgr shareInstance] registerClazzes:@[
                                           [Person class],
                                           ]];
```
## 主键
默认每个对象入库都会持有一个ID `[person ID]` , 作为数据库的主键，库通过这个 `ID` 来识别对象是否与数据库关联，所以不是必要时，不要操作此属性

### 自定义主键
**不同的业务需求，有可能使用的主键有特定的业务意义，需要自行定义。**

在需要自定义的实体类中实现一下方法

```objc
/// 自定义主键的对应的属性 （需要是属性的全名）
+ (NSString *)jr_customPrimarykey {
    return @"_name";
}
/// 自定义主键属性值
- (id)jr_customPrimarykeyValue {
    return self.name;
}

```

通过下面的方法可以获取对应的值

```objc
/**
 *  如果有自定义主键，则返回自定义主键key，例如 name，若没有实现，则返回默认主键key ： @"_ID"
 */
[Person jr_primaryKey];

/**
 * 如果有自定义主键，则返回自定义主键的值，如果没有，则返回 [self ID]
 */
[p jr_primaryKeyValue];
```

## 忽略字段

默认非数据库基本类型都会忽略不入库。

数据库基本类型:
 
- NSString
- NSDate
- NSData
- int, unsigned int, double, float, long.....

非以上类型都会自动忽略不入库。

若有特定需要忽略字段，需要实现一下方法

```objc
/// 忽略age属性，不做入库操作
+ (NSArray *)jr_excludePropertyNames {
    return @[
             @"_age",
             ];
}
```
---

<a id="tableId"></a>
# 表操作（TableOperation）

### 建表 
`J_CreateTable(Person)`
### 更新表

- 更新表时只会添加字段，不会删除或更新字段名，有需要的话需要自行写sql语句解决

`J_UpdateTable(Person)`
### 删除表
`J_DropTable(Person)`
### 重建表
`J_TruncateTable(Person)`

---

<a id="saveId"></a>
# 保存（Save）

```objc
    
BOOL result = J_Insert(p)
					.InDB([JRDBMgr defaultDB]) // by Default
					.Recursive(NO)  		       // by default
					.Sync(YES)			       // by default
					.Transaction(YES)	       // by default
					.updateResult;             // 执行
    
// 可以省略为
BOOL result = J_Insert(p).updateResult;
    
// 数组保存，两种 api 自由使用
BOOL result = J_Insert(p1, p2, p3).updateResult;
    
BOOL result = J_Insert(@[p1, p2, p3]).updateResult;
```

---

<a id="updateId"></a>
# 更新 （Update）

**更新操作需要提供对象的主键，请确保需要更新的对象都是从数据库查出来的；（也可以手动设置主键让库识别，不建议）**

```objc

BOOL result = J_Update(p)
					.Columns(@[@"_age", @"_name"])  // 更新指定列
				//	.Ignore(@[@"_age", @"_name"])   // 忽略指定列
					.InDB([JRDBMgr defaultDB])      // by default
					.Recursive(NO)                  // by default
					.Sync(YES)                      // by default
					.Transaction(YES)               // by default
					.updateResult;                  // 执行
					
BOOL result = J_Update(p).Ignore(@[@"_phone"]).updateResult;

// 更新数组
BOOL result = J_Update(p1, p2).updateResult;
BOOL result = J_Update(@[p1, p2, p3]).updateResult;

```

---
<a id="deleteId"></a>
# 删除（Delete）

**删除操作需要提供对象的主键，请确保需要更新的对象都是从数据库查出来的；（也可以手动设置主键让库识别，不建议）**

```objc
// 删除
BOOL result = J_Delete(p)
					.InDB([JRDBMgr defaultDB])      // by default
					.Recursive(NO)                  // by default
					.Sync(YES)                      // by default
					.Transaction(YES)               // by default
					.updateResult;                  // 执行
```

<a id="queryId"></a>
# 查询（Query）

```objc
// 普通查询
NSArray<Person *> *result =
				    J_Select(Person)    // 指定查询对象
				    .Recursive(YES)		// 默认 可省略
				    .Sync(YES)			// 默认 可省略
				    .Cache(NO)			// 默认 可省略
				    .Desc(NO)           // 默认 可省略
				    .Where(@"_name like ? and _height > ?")// 条件语句 可省略
				    .Params(@[@"L%", @150])                // 对应条件语句的 ? 可省略
				    .Group(@"_level")                      // Group 语句对应的字段 可省略
				    .Order(@"_age")                        // Order 语句对应的字段 可省略
				    .Limit(0, 10)                          // 分页 start, length 可省略
				    .list;

// 自定义查询
NSArray<Person *> *result1 =
						J_SelectColumns(@[@"_age", @"_name"])
						.From([Person class])
						.Recursive(YES)   // 在自定义查询中不会起作用
						.Sync(YES)		  //  默认 可省略
						.Cache(NO)		  // 在自定义查询中不会起作用
						.Where(@"_name like ? and _height > ?")
						.Params(@[@"L%", @150])
						.Group(@"_level")
						.Order(@"_age")
						.Limit(0, 10)
						.Desc(NO)
						.list;

NSUInteger count =
				J_SelectCount(Person) // 查询哪个类
				.Recursive(YES)   // 在自定义查询中不会起作用
				.Sync(YES)		  //  默认 可省略
				.Cache(NO)		  // 在自定义查询中不会起作用
				.Where(@"_name like ? and _height > ?")
				.Params(@[@"L%", @150])
				.Group(@"_level")
				.Order(@"_age")
				.Limit(0, 10)
				.Desc(NO)
				.count;
                    
```

<a id="configurationId"></a>
# 链式调用配置（Configuration）

| 配置        	| 功能		|参数类型| 
|:-------------:|------------| -------- |
| InDB		| [JRDBMgr defaultDB] by default;|FMDatabase * |
| From		| 自定义查询时指定的类名|Class |
| Recursive		| NO by default;<br/> NO:效率高，<br/>YES：[关联操作](#linkId)效率低|YES or NO|
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

---

<a id="linkId"></a>
# 关联操作（Link）

**描述：当一个类的一个属性为一个实体类，在操作数据库时，通过配置，也可以进行同时操作**

例如：当保存 Person 时，也想同时保存 card 对象， Money数组，以及 children数组， 则可以进行关联操作。需要在对应的类实现一下方法, 并且子对象也需要注册

```objc
// 注册子model类 
[[JRDBMgr shareInstance] registerClazzes:@[
                                           [Person class],
                                           [Card class],
                                           [Money class],
                                           ]];



@interface Person : NSObject

@property (nonatomic, strong) Card *card;
@property (nonatomic, strong) NSMutableArray<Money *> *money;
@property (nonatomic, strong) NSMutableArray<Person *> *children;

@end

@implementation

/// 单个对象关联
+ (NSDictionary<NSString *,Class<JRPersistent>> *)jr_singleLinkedPropertyNames {
    return @{
             @"_card" : [Card class],
             };
}

/// 数组对象关联
+ (NSDictionary<NSString *,Class<JRPersistent>> *)jr_oneToManyLinkedPropertyNames {
    return @{
             @"_money" : [Money class],
             @"_children" : [Person class],
             };
}

@end

```

<a id='linksave'></a>
### 关联操作 （保存） 

```objc
Person *p = [Person new];
Card *c = [Card new];
p.card = c;
p.money = @[m1,m2,m3];
p.children = @[p1,p2,p3];

BOOL result = J_Insert(p)
					.Recursive(YES) // 默认为NO， 需要手动指定关联保存
					.updateResult;

```

<a id='linkupdate'></a>
### 关联操作（更新）

**注意：若子对象都是没有保存过的（既数据库没有的对象），则全部保存。若有已存在对象，不保存不更新。**
 
* 出于更新的操作的随意性比较重，更新时不进行一切关联操作，即更新时，只更新本model相关信息，不更新所有子model的信息。当层级较多的时候，需要从子层级开始一步一步开始更新上来（所以不建议建立太多层级）

* 更新本model的信息包括：
   * 子model的ID会保存（若有）
   * 子model数组的数量（若子model数组数量发生变更会更新，但是子model的数组不会更到数据库）
	

```		
BOOL result = J_Update(p).Recursive(YES).updateResult;
```

--

<a id='linkdelete'></a>
### 关联操作（删除）
* 和更新一样，删除时，只会删除本model的信息，不会进行一切关联操作。
* 删除时，会删除一对多的中间表无用信息

```		
BOOL result = J_Delete(p).Recursive(YES).updateResult;
```

---

<a id='linkselect'></a>
### 关联操作（查询）

```objc
NSArray<Person *> *list = J_Select(Person).Recursive(YES).list;
```

---



<a id="macroId"></a>
# 宏（Macro） 

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

---

<a id="subQueryId"></a>
# 子查询（SubQuery）

```objc
// 正常查询只能先排序再分页，加入子查询，可以先分页，再从子结果中排序 . ie. 

NSArray<Person *> *list =J_Select(Person)
                                .From(
                                    J_Select(Person).Limit(0, 10) // 放入一个子查询，外部查询则从子查询的结果里继续查询
                                ).OrderJ(age)
                                .Descend
                                .list;

```

---

<a id="categoryId"></a>
# NSObject+JRDB

**给NSObject添加分类方法，以方便快捷的方式使用本库的渐变功能**

```objc

- (BOOL)jr_saveOrUpdateOnly;// 非关联操作
- (BOOL)jr_saveOrUpdate;	 // 关联操作

#pragma mark - save

- (BOOL)jr_saveOnly;
- (BOOL)jr_save;

#pragma mark - update

- (BOOL)jr_updateOnlyColumns:(NSArray<NSString *> * _Nullable)columns;
- (BOOL)jr_updateColumns:(NSArray<NSString *> * _Nullable)columns;

- (BOOL)jr_updateOnlyIgnore:(NSArray<NSString *> * _Nullable)Ignore;
- (BOOL)jr_updateIgnore:(NSArray<NSString *> * _Nullable)Ignore;

#pragma mark - delete

+ (BOOL)jr_deleteAllOnly;
+ (BOOL)jr_deleteAll;

- (BOOL)jr_deleteOnly;
- (BOOL)jr_delete;

#pragma mark - select

/// 关联查询
+ (instancetype _Nullable)jr_findByID:(NSString * _Nonnull)ID;
+ (instancetype _Nullable)jr_findByPrimaryKey:(id _Nonnull)primaryKey;
+ (NSArray<id<JRPersistent>> * _Nonnull)jr_findAll;

/// 非关联查询
+ (instancetype _Nullable)jr_getByID:(NSString * _Nonnull)ID;
+ (instancetype _Nullable)jr_getByPrimaryKey:(id _Nonnull)primaryKey;
+ (NSArray<id<JRPersistent>> * _Nonnull)jr_getAll;

```

---

<a id='threadId'></a>
# 线程安全

**使用本库的数据库，都是阻塞本线程，并且线程安全的，所有操作带有事务。<br/>操作本库管理的数据库时，请使用本库提供的API进行操作，否则有可能产生数据库锁问题**

---
# 泛型提示

![abc](https://raw.githubusercontent.com/scubers/JRDB/master/generic_tip.png)

通过泛型，查询出来后，编译器直接识别结果为对应对象，减少强转操作。
