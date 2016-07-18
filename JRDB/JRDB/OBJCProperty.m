//
//  OBJCProperty.m
//  JRDB
//
//  Created by 王俊仁 on 16/6/5.
//  Copyright © 2016年 Jrwong. All rights reserved.
//

#import "OBJCProperty.h"

#define TONSString(s) [NSString stringWithUTF8String:s]

@interface OBJCProperty()
{
    objc_property_t _prop;

    NSMutableDictionary<NSString *, NSString *> *_attributeDict;
}
@end

@implementation OBJCProperty

@synthesize name            = _name;
@synthesize ivarName        = _ivarName;
@synthesize typeEncoding    = _typeEncoding;
@synthesize oldTypeEncoding = _oldTypeEncoding;
@synthesize ownerShip       = _ownerShip;
@synthesize isNonatomic     = _isNonatomic;

+ (instancetype)prop:(objc_property_t)prop {
    OBJCProperty *p = [[OBJCProperty alloc] init];
    p->_prop = prop;
    p->_name = [NSString stringWithUTF8String:property_getName(prop)];
    p->_attributeDict = [NSMutableDictionary dictionary];
    unsigned int outCount;
    objc_property_attribute_t *attrs = property_copyAttributeList(prop, &outCount);
    for (int i = 0; i < outCount; i++) {
        objc_property_attribute_t attr = attrs[i];
        p->_attributeDict[TONSString(attr.name)] = TONSString(attr.value).length ? TONSString(attr.value) : @"";
    }
    free(attrs);
    return p;
}


- (PropAttrOwnerShip)ownerShip {
    if (_attributeDict[OBJCPropertyCopyAttribute]) { return PropAttrOwnerShipCopy; }
    else if(_attributeDict[OBJCPropertyRetainAttribute]) { return PropAttrOwnerShipStrong; }
    else if(_attributeDict[OBJCPropertyWeakReferenceAttribute]) { return PropAttrOwnerShipWeak; }
    else return PropAttrOwnerShipAssign;
}

- (BOOL)isNonatomic {
    return [_attributeDict[OBJCPropertyNonAtomicAttribute] boolValue];
}

- (NSString *)ivarName {
    return _attributeDict[OBJCPropertyBackingIVarNameAttribute];
}

- (NSString *)typeEncoding {
    return _attributeDict[OBJCPropertyTypeEncodingAttribute];
}

- (NSString *)oldTypeEncoding {
    return _attributeDict[OBJCPropertyOldTypeEncodingAttribute];
}

- (BOOL)isReadOnly {
    return [_attributeDict[OBJCPropertyReadOnlyAttribute] boolValue];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"--------\n   name: %@\n   type: %@ \n   ownerShip:%@\n   isNonatomic: %@\n   ivarName: %@", self.name, self.typeEncoding, [self ownerShipString], @(self.isNonatomic), self.ivarName];
}

- (NSString *)ownerShipString {
    switch (_ownerShip) {
        case PropAttrOwnerShipCopy: return @"Copy";
        case PropAttrOwnerShipAssign: return @"Assign";
        case PropAttrOwnerShipStrong: return @"Strong";
        case PropAttrOwnerShipWeak: return @"Weak";
        default: return nil;
    }
}

@end


NSString * const OBJCPropertyTypeEncodingAttribute                  = @"T";

NSString * const OBJCPropertyCopyAttribute                          = @"C";
NSString * const OBJCPropertyRetainAttribute                        = @"&";
NSString * const OBJCPropertyWeakReferenceAttribute                 = @"W";

NSString * const OBJCPropertyNonAtomicAttribute                     = @"N";
NSString * const OBJCPropertyBackingIVarNameAttribute               = @"V";

NSString * const OBJCPropertyCustomGetterAttribute                  = @"G";
NSString * const OBJCPropertyCustomSetterAttribute                  = @"S";
NSString * const OBJCPropertyDynamicAttribute                       = @"D";
NSString * const OBJCPropertyEligibleForGarbageCollectionAttribute  = @"P";
NSString * const OBJCPropertyOldTypeEncodingAttribute               = @"t";
NSString * const OBJCPropertyReadOnlyAttribute                      = @"R";
