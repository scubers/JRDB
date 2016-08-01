//
//  OBJCProperty.h
//  JRDB
//
//  Created by 王俊仁 on 16/6/5.
//  Copyright © 2016年 Jrwong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>


//    NSString 的objc_property_attributes
//    name: T  value: @"NSString"  type
//    name: &  value:              &: string, C: copy, W: weak, nil: assign
//    name: N  value:              N: isNonatomic, nil atomic
//    name: V  value: _name        V: 对应的ivar名

typedef NS_ENUM(NSInteger, PropAttrOwnerShip) {
    PropAttrOwnerShipAssign,
    PropAttrOwnerShipCopy,
    PropAttrOwnerShipStrong,
    PropAttrOwnerShipWeak,
} ;


@interface OBJCProperty : NSObject

//- (instancetype)initWithProperty:(objc_property_t)prop;
+ (instancetype)prop:(objc_property_t)prop;

@property (nonatomic, copy, readonly  ) NSString          *name;

#pragma mark - objc property attributes
@property (nonatomic, copy, readonly  ) NSString          *typeEncoding;///< T
@property (nonatomic, copy, readonly  ) NSString          *oldTypeEncoding;///< t
@property (nonatomic, copy, readonly  ) NSString          *ivarName;///< N
@property (nonatomic, assign, readonly) PropAttrOwnerShip ownerShip;///< &: string, C: copy, W: weak, nil: assign
@property (nonatomic, assign, readonly) BOOL              isNonatomic;

@property (nonatomic, assign, readonly) BOOL              isReadOnly;

@end

extern NSString * const OBJCPropertyTypeEncodingAttribute;
extern NSString * const OBJCPropertyBackingIVarNameAttribute;
extern NSString * const OBJCPropertyCopyAttribute;
extern NSString * const OBJCPropertyRetainAttribute;
extern NSString * const OBJCPropertyCustomGetterAttribute;
extern NSString * const OBJCPropertyCustomSetterAttribute;
extern NSString * const OBJCPropertyDynamicAttribute;
extern NSString * const OBJCPropertyEligibleForGarbageCollectionAttribute;
extern NSString * const OBJCPropertyNonAtomicAttribute;
extern NSString * const OBJCPropertyOldTypeEncodingAttribute;
extern NSString * const OBJCPropertyReadOnlyAttribute;
extern NSString * const OBJCPropertyWeakReferenceAttribute;