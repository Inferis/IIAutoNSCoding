//
// ** File:     NSObject+PropertyDescription.m
// ** Location: ~/BGANTESharedLibrary/Categories/NSObject+PropertyDescription
//

#import "NSObject+PropertyDescription.h"
#import <objc/runtime.h>
#import <UIKit/UIKit.h>

#define isPrefix(class, prefix) ([NSStringFromClass(class) rangeOfString:prefix].location == 0)

@implementation NSObject (PropertyDescription)

- (NSArray *)propertyDescriptionInternal:(Class)class usingTypes:(BOOL)usingTypes {
    if (!class) class = [self class];

    if (isPrefix(class, @"NS") || isPrefix(class, @"CA") || isPrefix(class, @"UI") || isPrefix(class, @"CA")) {
        return @[[self description]];
    }

    unsigned int outCount, i;
    objc_property_t *properties = class_copyPropertyList(class, &outCount);

    if ([self isKindOfClass:[NSDictionary class]]) {
        NSMutableArray *result = [NSMutableArray arrayWithObject:@"("];
        for (id item in (id<NSFastEnumeration>)self) {
            NSArray *keyDescription = [item propertyDescriptionInternal:nil usingTypes:usingTypes];
            [result addObject:[NSString stringWithFormat:@"    %@", [keyDescription objectAtIndex:0]]];
            for (NSString *line in [keyDescription subarrayWithRange:NSMakeRange(1, keyDescription.count - 1)]) {
                [result addObject:[@"    " stringByAppendingString:line]];
            }
            NSString *line = [result lastObject];
            [result removeLastObject];
            NSArray *valueDescription = [((NSDictionary*)self)[item] propertyDescriptionInternal:nil usingTypes:usingTypes];
            [result addObject:[NSString stringWithFormat:@"%@: %@", line, [valueDescription objectAtIndex:0]]];
            for (NSString *line in [valueDescription subarrayWithRange:NSMakeRange(1, valueDescription.count - 1)]) {
                [result addObject:[@"    " stringByAppendingString:line]];
            }
        }
        [result addObject:@")"];
        return result;
    }
    else  if ([self conformsToProtocol:@protocol(NSFastEnumeration)]) {
        NSMutableArray *result = [NSMutableArray arrayWithObject:@"("];
        for (id item in (id<NSFastEnumeration>)self) {
            NSArray *valueDescription = [item propertyDescriptionInternal:nil usingTypes:usingTypes];
            [result addObject:[NSString stringWithFormat:@"    %@", [valueDescription objectAtIndex:0]]];
            for (NSString *line in [valueDescription subarrayWithRange:NSMakeRange(1, valueDescription.count - 1)]) {
                [result addObject:[@"    " stringByAppendingString:line]];
            }
        }
        [result addObject:@")"];
        return result;
    }
    
    NSMutableArray *result = [NSMutableArray arrayWithObject:[NSString stringWithFormat:@"<%@:#%lu> {", [self class], (unsigned long)[self hash]]];
    while (YES) {
        for (i = 0; i < outCount; i++) { 
            objc_property_t property = properties[i];
            NSString *aName = [NSString stringWithCString:property_getName(property) encoding:NSUTF8StringEncoding];

            if ([aName isEqualToString:@"description"] || [aName isEqualToString:@"debugDescription"]) {
                continue;
            }
            
            char *attrValue = property_copyAttributeValue(property, "T");
            NSString *type = [NSString stringWithUTF8String:attrValue];
            free(attrValue);
            
            attrValue = property_copyAttributeValue(property, "G");
            NSString *getter = attrValue ? [NSString stringWithUTF8String:attrValue] : aName;
            free(attrValue);

            NSArray *valueDescription = nil;
            if ([type rangeOfString:@":"].location != NSNotFound) {
                valueDescription = @[ @"SEL" ];
            }
            else if ([self respondsToSelector:NSSelectorFromString(getter)]) {
                id value = [self valueForKey:aName];
                if ([value isKindOfClass:[UIView class]]) {
                    valueDescription = @[ [value class] ];
                }
                else if ([value isKindOfClass:[CALayer class]]) {
                    valueDescription = @[ [value class] ];
                }
                else {
                    valueDescription = [value propertyDescriptionInternal:nil usingTypes:usingTypes];
                }
            }
            else {
                valueDescription = @[ @"@optional" ];
            }

            if (valueDescription.count > 0) {
                [result addObject:[NSString stringWithFormat:@"    %@ = %@", aName, [valueDescription objectAtIndex:0]]];
                for (NSString *line in [valueDescription subarrayWithRange:NSMakeRange(1, valueDescription.count - 1)]) {
                    [result addObject:[@"    " stringByAppendingString:line]];
                }
            }
        }
        
        class = [class superclass];
        if (!class || [NSStringFromClass(class) rangeOfString:@"NS"].location == 0) break;

        free(properties);
        properties = class_copyPropertyList(class, &outCount);
    }
    free(properties);
    
    if (result.count == 1) {
        NSString *descr;
        id value = self;
        if ([self isKindOfClass:[NSString class]]) {
            value = [NSString stringWithFormat:@"\"%@\"", self];
        }
        else if ([self class] == self) {
            value = [NSString stringWithFormat:@"%s", class_getName((Class)self)];
        }
        
        if (usingTypes)
            descr = [NSString stringWithFormat:@"<%@:#%lu> %@", [self class], (unsigned long)[self hash], value];
        else {
            descr = [NSString stringWithFormat:@"%@", value];
        }
        result = [NSMutableArray arrayWithObject:descr];
    }
    else
        [result addObject:@"}"];

    return result;
}

- (NSString *)propertyDescription {
    return [[self propertyDescriptionInternal:nil usingTypes:YES] componentsJoinedByString:@"\n"];
}

- (NSString *)propertyDescriptionWithoutTypes {
    return [[self propertyDescriptionInternal:nil usingTypes:NO] componentsJoinedByString:@"\n"];
}

- (NSArray *)propertyHashInternal:(Class)class {
    if (!class) class = [self class];
    unsigned int outCount, i;
    objc_property_t *properties = class_copyPropertyList(class, &outCount);
    
    NSMutableArray *result = [NSMutableArray arrayWithObject:[NSNumber numberWithUnsignedInteger:[self hash]]];
    while (YES) {
        for (i = 0; i < outCount; i++) { 
            objc_property_t property = properties[i];
            NSString *aName = [NSString stringWithCString:property_getName(property) encoding:NSUTF8StringEncoding];
            
            [result addObjectsFromArray:[[self valueForKey:aName] propertyHashInternal:nil]];
        }
        
        class = [class superclass];
        if (!class || [NSStringFromClass(class) rangeOfString:@"NS"].location == 0) break;
        
        free(properties);
        properties = class_copyPropertyList(class, &outCount);
    }
    free(properties);
    
    return result;
}

- (uint)propertyHash {
    __block uint hash = 0;
    [[self propertyHashInternal:nil] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        hash ^= [obj unsignedIntValue];
    }];
    return hash;
}



@end
