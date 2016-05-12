# JRDB
---------
- 使用分类的模式，模仿Hibernate，对FMDB进行简易封装
- 支持pod 安装 『pod 'JRDB'』 ,Podfile需要添加  use_framework! 
- 使用协议，不用继承基类，对任意NSObject可以进行入库操作
- 支持swift 和 Objective-c
- 支持数据类型：基本数据类型（int，double，等），String，NSData，NSNumber，NSDate
  - 注：swift的基本数据类型，不支持Option类型，既不支持Int？Int！等，对象类型支持Option类型
