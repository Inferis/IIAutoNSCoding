//
//  IIAutoNSCoding.m
//  AutoNSCodingDemo
//
//  Created by Tom Adriaenssen on 27/05/15.
//  Copyright (c) 2015 Tom Adriaenssen. All rights reserved.
//

#import "IIAutoNSCoding.h"

#import <dlfcn.h>
#import <objc/message.h>
#import <objc/runtime.h>

#import <mach-o/dyld.h>
#import <mach-o/getsect.h>

NSArray *IIFindClassesForAutoNSCoding();

void IIAutoNSCodingAdoptSecureCoding(Class class) {
    // add the nscoding protocol
    class_addProtocol(class, @protocol(NSSecureCoding));
    
    // add the 'supportsSecureCoding' method
    Method method = class_getClassMethod(class, @selector(supportsSecureCoding));
    IMP impl = imp_implementationWithBlock(^BOOL(id self) {
        return YES;
    });
    Class metaClass = objc_getMetaClass(class_getName(class));
    class_addMethod(metaClass, @selector(supportsSecureCoding), impl, method_getTypeEncoding(method));
}

void IIAutoNSCodingAddMethod(Class class, SEL selector, id block) {
    struct objc_method_description method = protocol_getMethodDescription(@protocol(NSCoding), selector, YES, YES);
    IMP impl = imp_implementationWithBlock(block);
    class_addMethod(class, selector, impl, method.types);
}

NSArray *IIAutoNSCodingDiscoverMapping(Class class) {
    NSMutableArray *mapping = [NSMutableArray new];
    
    uint count = 0;
    objc_property_t *properties = class_copyPropertyList(class, &count);
    for (uint i=0; i<count; ++i) {
        objc_property_t property = properties[i];

        char *attrValue = NULL;
        attrValue = property_copyAttributeValue(property, "R");
        BOOL readonly = attrValue != NULL;
        free(attrValue);

        if (readonly) { continue; }

        attrValue = property_copyAttributeValue(property, "T");
        NSString *type = [NSString stringWithUTF8String:attrValue];
        free(attrValue);
        
        if (!type) { continue; }

        NSString *name = [NSString stringWithUTF8String:property_getName(property)];
        
        attrValue = property_copyAttributeValue(property, "G");
        NSString *getter = attrValue ? [NSString stringWithUTF8String:attrValue] : name;
        free(attrValue);

        attrValue = property_copyAttributeValue(property, "S");
        NSString *setter = attrValue ? [NSString stringWithUTF8String:attrValue] : [NSString stringWithFormat:@"set%@%@:", [[name substringToIndex:1] uppercaseString], [name substringFromIndex:1]];
        free(attrValue);
        
        if (type.length >= 3) {
            NSString *className = [type substringWithRange:NSMakeRange(2, type.length-3)];
            Class class = NSClassFromString(className);
            if (class) {
                [mapping addObject:@{ @"n": name,
                                      @"c": class,
                                      @"g": [NSValue valueWithPointer:NSSelectorFromString(getter)],
                                      @"s": [NSValue valueWithPointer:NSSelectorFromString(setter)] }];
            }
            else {
                @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                               reason:@"NOT SUPPORTED" userInfo:nil];
            }
        }
        else {
            [mapping addObject:@{ @"n": name,
                                  @"t": type,
                                  @"g": [NSValue valueWithPointer:NSSelectorFromString(getter)],
                                  @"s": [NSValue valueWithPointer:NSSelectorFromString(setter)] }];
        }
    }
    free(properties);
    
    return [mapping copy];
}

id IIAutoNSCodingInitializer(Class class, id self, NSCoder *coder) {
    Class superclass = class_getSuperclass(class);
    
    if (class_conformsToProtocol(superclass, @protocol(NSCoding))) {
        struct objc_super mySuper = {
            .receiver = self,
            .super_class = superclass
        };
        
        id (*objc_superInit)(struct objc_super *, SEL, NSCoder *) = (void *)&objc_msgSendSuper;
        self = (*objc_superInit)(&mySuper, @selector(initWithCoder:), coder);
    }
    else {
        id (*objc_selfInit)(id, SEL) = (void *)&objc_msgSend;
        self = (*objc_selfInit)(self, @selector(init));
    }
    
    return self;
}

#define SET_VALUE(object, selector, type, value) \
    void(*objc_msgSendTyped)(id, SEL, type) = (void *)objc_msgSend; \
    objc_msgSendTyped(self, selector, value);

void IIAutoNSCodingDecoder(Class class, NSArray *mapping, id self, NSCoder *coder) {
    for (NSDictionary *map in mapping) {
        NSString *name = map[@"n"];

        Class class = map[@"c"];
        SEL selector = [map[@"s"] pointerValue];
        if (class) {
            id value = [coder decodeObjectOfClass:class forKey:name];
            SET_VALUE(self, selector, id, value);
        }
        else {
            id value = [coder decodeObjectOfClass:[NSNumber class] forKey:name];
            char type = [map[@"t"] characterAtIndex:0];
            switch (type) {
                case ':': { // selector
                    SET_VALUE(self, selector, SEL, NSSelectorFromString(value));
                    break;
                }

                case 'i': { // int
                    SET_VALUE(self, selector, int, [value intValue]);
                    break;
                }
                    
                case 's': { // short
                    SET_VALUE(self, selector, short, [value shortValue]);
                    break;
                }
                    
                case 'l': { // long
                    SET_VALUE(self, selector, short, [value longValue]);
                    break;
                }
                    
                case 'q': { // long long
                    SET_VALUE(self, selector, short, [value longLongValue]);
                    break;
                }
                    
                case 'I': { // unsigned int
                    SET_VALUE(self, selector, short, [value unsignedIntValue]);
                    break;
                }
                    
                case 'S': { // unsigned short
                    SET_VALUE(self, selector, short, [value unsignedShortValue]);
                    break;
                }
                    
                case 'L': { // unsigned long
                    SET_VALUE(self, selector, short, [value unsignedLongValue]);
                    break;
                }
                    
                case 'Q': { // unsigned long long
                    SET_VALUE(self, selector, short, [value unsignedLongLongValue]);
                    break;
                }
                    
                case 'f': { // float
                    SET_VALUE(self, selector, short, [value floatValue]);
                    break;
                }
                    
                case 'd': { // double
                    SET_VALUE(self, selector, short, [value doubleValue]);
                    break;
                }
                    
                case 'B': { // BOOL
                    SET_VALUE(self, selector, short, [value boolValue]);
                    break;
                }
                    
                case 'c': { // char
                    SET_VALUE(self, selector, short, [value charValue]);
                    break;
                }
                    
                case 'C': { // unsigned char
                    SET_VALUE(self, selector, short, [value unsignedCharValue]);
                    break;
                }
                    
                default:
                    break;
            }
        }
    }
}

#define GET_VALUE(obj, selector, type) ({ \
    type(*objc_msgSendTyped)(id, SEL) = (void *)objc_msgSend; \
    objc_msgSendTyped(obj, selector); })

void IIAutoNSCodingEncoder(Class class, NSArray *mapping, id self, NSCoder *coder, NSString *options) {
    __block void(^autoInject)(Class, id) = ^(Class class, __unused id value) { };
    
    if ([options containsString:AUTO_INJECT_CHILDREN]) {
        autoInject = ^(Class injectClass, id value) {
            if (!injectClass || !value) return;
            
            [IIAutoNSCoding inject:injectClass options:options];
            if ([value isKindOfClass:[NSArray class]]) {
                for (id item in value) {
                    [IIAutoNSCoding inject:[item class] options:options];
                }
            }
            else if ([injectClass isSubclassOfClass:[NSSet class]]) {
                for (id item in value) {
                    [IIAutoNSCoding inject:[item class] options:options];
                }
            }
            else if ([injectClass isSubclassOfClass:[NSDictionary class]]) {
                for (id itemKey in value) {
                    [IIAutoNSCoding inject:[itemKey class] options:options];
                    id itemValue = value[itemKey];
                    [IIAutoNSCoding inject:[itemValue class] options:options];
                }
            }
        };
    }

    for (NSDictionary *map in mapping) {
        NSString *name = map[@"n"];
        
        Class class = map[@"c"];
        SEL selector = [map[@"g"] pointerValue];
        if (class) {
            id value = GET_VALUE(self, selector, id);
            autoInject(class, value);
            [coder encodeObject:value forKey:name];
        }
        else {
            id value = nil;
            char type = [map[@"t"] characterAtIndex:0];
            switch (type) {
                case ':': { // selector
                    value = NSStringFromSelector(GET_VALUE(self, selector, SEL));
                    break;
                }

                case 'i': { // int
                    value = @(GET_VALUE(self, selector, int));
                    break;
                }
                    
                case 's': { // short
                    value = @(GET_VALUE(self, selector, short));
                    break;
                }
                    
                case 'l': { // long
                    value = @(GET_VALUE(self, selector, long));
                    break;
                }
                    
                case 'q': { // long long
                    value = @(GET_VALUE(self, selector, long long));
                    break;
                }
                    
                case 'I': { // unsigned int
                    value = @(GET_VALUE(self, selector, unsigned int));
                    break;
                }
                    
                case 'S': { // unsigned short
                    value = @(GET_VALUE(self, selector, unsigned short));
                    break;
                }
                    
                case 'L': { // unsigned long
                    value = @(GET_VALUE(self, selector, unsigned long));
                    break;
                }
                    
                case 'Q': { // unsigned long long
                    value = @(GET_VALUE(self, selector, unsigned long long));
                    break;
                }
                    
                case 'f': { // float
                    value = @(GET_VALUE(self, selector, float));
                    break;
                }
                    
                case 'd': { // double
                    value = @(GET_VALUE(self, selector, double));
                    break;
                }
                    
                case 'B': { // BOOL
                    value = @(GET_VALUE(self, selector, BOOL));
                    break;
                }
                    
                case 'c': { // char
                    value = @(GET_VALUE(self, selector, char));
                    break;
                }
                    
                case 'C': { // unsigned char
                    value = @(GET_VALUE(self, selector, unsigned char));
                    break;
                }
                    
                default:
                    break;
            }
            
            [coder encodeObject:value forKey:name];
        }
    }
}

@implementation IIAutoNSCoding

+ (void)inject:(Class)class options:(NSString*)options
{
    // don't inject if already nscoding
    if (!class || class_conformsToProtocol(class, @protocol(NSCoding))) {
        return;
    }
    
    // only do stuff in our app bundle
    NSString *name = [[NSString alloc] initWithUTF8String:class_getImageName(class)];
    if ([name rangeOfString:[[NSBundle mainBundle] bundlePath]].location == NSNotFound) {
        return;
    }

    Class superclass = class_getSuperclass(class);
    if (!class_conformsToProtocol(superclass, @protocol(NSCoding))) {
        [self inject:superclass options:options];
    }

    IIAutoNSCodingAdoptSecureCoding(class);
    
    NSArray *mapping = IIAutoNSCodingDiscoverMapping(class);
    IIAutoNSCodingAddMethod(class, @selector(initWithCoder:), ^(Class self, NSCoder* decoder) {
        self = IIAutoNSCodingInitializer(class, self, decoder);
        IIAutoNSCodingDecoder(class, mapping, self, decoder);
        return self;
    });
    IIAutoNSCodingAddMethod(class, @selector(encodeWithCoder:), ^(Class self, NSCoder* coder) {
        IIAutoNSCodingEncoder(class, mapping, self, coder, options);
    });
}

@end