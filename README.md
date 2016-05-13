#JRDB

**一个对FMDB进行类Hibernate封装的ios库，支持Objective-c 和 Swift。**

GitHub: [sucbers](https://github.com/scubers)

Feedback: [jr-wong@qq.com](mailto:jrwong@qq.com)

--

#Description

- 使用分类的模式，模仿Hibernate，对FMDB进行简易封装
- 支持pod 安装 『pod 'JRDB'』，Podfile需要添加  use_framework! 
- 使用协议，不用继承基类，对任意NSObject可以进行入库操作
- 支持swift 和 Objective-C
- 支持数据类型：基本数据类型（int，double，等），String，NSData，NSNumber，NSDate
  - 注：swift的基本数据类型，不支持**Option**类型，既不支持Int？Int！等，对象类型支持**Option**类型

--

#Usage


###Save 【保存】
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

--

###Update 【更新】

```objc
Person *p = [Person jr_findAll];
p.name = @"abc";
[p jr_update columns:nil];
```
	column: 需要更新的字段名，传入空为全量更新

--

###Delete 【删除】

```objc
Person *p = [Person jr_findAll];
[p jr_delete];
```
--
###Select 【查找】

- 常规查找

```objc
Person *P = [Person jr_findByID:@"111"];
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
--

#Other 【其他】

###协议：JRPersistent

```objc
@protocol JRPersistent <NSObject>
@required
- (void)setID:(NSString *)ID;
- (NSString *)ID;
@optional
/**
 *  返回不用入库的对象字段数组
 *  The full property names that you want to ignore for persistent
 *  
 *  @return array
 */
+ (NSArray *)jr_excludePropertyNames;
@end
```

###默认NSObject分类实现

```objc
@interface NSObject (JRDB) <JRPersistent>
(...methods)
@end
```

--
###JRDBMgr

```objc
@interface JRDBMgr : NSObject
@property (nonatomic, strong) FMDatabase *defaultDB;
+ (instancetype)shareInstance;
+ (FMDatabase *)defaultDB;
- (FMDatabase *)createDBWithPath:(NSString *)path;
- (void)deleteDBWithPath:(NSString *)path;
/**
 *  在这里注册的类，使用本框架的数据库将全部建有这些表
 *  @param clazz 类名
 */
- (void)registerClazzForUpdateTable:(Class<JRPersistent>)clazz;
- (NSArray<Class> *)registedClazz;
/**
 * 更新默认数据库的表（或者新建没有的表）
 * 更新的表需要在本类先注册
 */
- (void)updateDefaultDB;
- (void)updateDB:(FMDatabase *)db;
@end
```

JRDBMgr持有一个默认数据库（~/Documents/jrdb/jrdb.sqlite），任何不指定数据库的操作，都在此数据库进行操作。默认数据库可以自行设置。

######Method

	- (void)registerClazzForUpdateTable:(Class<JRPersistent>)clazz;

在JRDBMgr中注册的类，可以使用

	-(void)updateDB:(FMDatabase *)db
进行统一更新或者创建表。	

#MoreUsage
- 查看FMDatabase+JRDB.h

--
