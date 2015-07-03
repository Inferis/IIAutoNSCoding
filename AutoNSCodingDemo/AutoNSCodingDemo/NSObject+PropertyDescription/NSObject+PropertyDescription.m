//
// ** File:     NSObject+PropertyDescription.m
// ** Location: ~/BGANTESharedLibrary/Categories/NSObject+PropertyDescription
//

#import "NSObject+PropertyDescription.h"
#import <objc/runtime.h>
#import <UIKit/UIKit.h>

#define isPrefix(class, prefix) ([NSStringFromClass(class) rangeOfString:prefix].location == 0)

#define getValue(obj, selector, type) ({ type(*objc_msgSendTyped)(id, SEL) = (void *)objc_msgSend; objc_msgSendTyped(obj, selector); })

@implementation NSObject (PropertyDescription)

- (NSArray *)propertyDescriptionInternal:(Class)class usingTypes:(BOOL)usingTypes {
    if (!class) class = [self class];

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

    unsigned int outCount, i;
    objc_property_t *properties = class_copyPropertyList(class, &outCount);

    NSMutableArray *result = [NSMutableArray arrayWithObject:[NSString stringWithFormat:@"<%@:#%lu> {", [self class], (unsigned long)[self hash]]];
    while (YES) {
        for (i = 0; i < outCount; i++) { 
            objc_property_t property = properties[i];
            NSString *aName = [NSString stringWithUTF8String:property_getName(property)];

            if ([aName isEqualToString:@"description"] || [aName isEqualToString:@"debugDescription"]) {
                continue;
            }
            
            char *attrValue = property_copyAttributeValue(property, "T");
            NSString *type = [NSString stringWithUTF8String:attrValue];
            free(attrValue);
            
            attrValue = property_copyAttributeValue(property, "G");
            SEL getter = NSSelectorFromString(attrValue ? [NSString stringWithUTF8String:attrValue] : aName);
            free(attrValue);
            
            NSArray *valueDescription = nil;
            if (!getter || [self respondsToSelector:getter]) {
                valueDescription = @[@"@optional"];
            }

            id value = nil;
            BOOL foundValue = NO;
            if ([type characterAtIndex:0] == '@' && type.length >= 3) {
                NSString *className = [type substringWithRange:NSMakeRange(2, type.length-3)];
                Class class = NSClassFromString(className);

                if (class) {
                    value = getValue(self, getter, id);
                    foundValue = YES;
                    valueDescription = [value propertyDescriptionInternal:nil usingTypes:usingTypes];
                }
                else {
                    valueDescription = @[[NSString stringWithFormat:@"?(%@)", type]];
                }
            }
            else {
                foundValue = YES;
                switch ([type characterAtIndex:0]) {
                    case ':': { // selector
                        value = [NSString stringWithFormat:@"@selector(%@)", NSStringFromSelector(getValue(self, getter, SEL))];
                        break;
                    }
                        
                    case 'i': { // int
                        value = @(getValue(self, getter, int));
                        break;
                    }
                        
                    case 's': { // short
                        value = @(getValue(self, getter, short));
                        break;
                    }
                        
                    case 'l': { // long
                        value = @(getValue(self, getter, long));
                        break;
                    }
                        
                    case 'q': { // long long
                        value = @(getValue(self, getter, long long));
                        break;
                    }
                        
                    case 'I': { // unsigned int
                        value = @(getValue(self, getter, unsigned int));
                        break;
                    }
                        
                    case 'S': { // unsigned short
                        value = @(getValue(self, getter, unsigned short));
                        break;
                    }
                        
                    case 'L': { // unsigned long
                        value = @(getValue(self, getter, unsigned long));
                        break;
                    }
                        
                    case 'Q': { // unsigned long long
                        value = @(getValue(self, getter, unsigned long long));
                        break;
                    }
                        
                    case 'f': { // float
                        value = @(getValue(self, getter, float));
                        break;
                    }
                        
                    case 'd': { // double
                        value = @(getValue(self, getter, double));
                        break;
                    }
                        
                    case 'B': { // BOOL
                        value = @(getValue(self, getter, BOOL));
                        break;
                    }
                        
                    case 'c': { // char
                        value = @(getValue(self, getter, char));
                        break;
                    }
                        
                    case 'C': { // unsigned char
                        value = @(getValue(self, getter, unsigned char));
                        break;
                    }
                        
                    case '#': { // class
                        value = [NSString stringWithFormat:@"@class(%@)", NSStringFromClass(getValue(self, getter, Class))];
                        break;
                    }

                    case '{': { // struct
                        value = getValue(self, getter, void*) ? [NSString stringWithFormat:@"@struct(%@)", type] : nil;
                        break;
                    }

                    case '^': { // pointer
                        void *ptr = getValue(self, getter, void*);
                        value = ptr ? [NSString stringWithFormat:@"@pointer(%p)", ptr] : nil;
                        break;
                    }

                    case '@': { // block
                        id block = getValue(self, getter, id);
                        value = block ? [NSString stringWithFormat:@"@block(%@)", block] : nil;
                        break;
                    }

                    default: {
                        foundValue = NO;
                        break;
                    }
                }
            }

            if (foundValue) {
                valueDescription = value ? [value propertyDescriptionInternal:nil usingTypes:usingTypes] : @[@"nil"];
            }
            else {
                valueDescription = @[[NSString stringWithFormat:@"?(%@)", type]];
            }

            if (valueDescription.count > 0) {
                [result addObject:[NSString stringWithFormat:@"    %@ = %@", aName, [valueDescription objectAtIndex:0]]];
                for (NSString *line in [valueDescription subarrayWithRange:NSMakeRange(1, valueDescription.count - 1)]) {
                    [result addObject:[@"    " stringByAppendingString:line]];
                }
            }
        }
        
        class = [class superclass];
        if (!class) { break; }

        NSString *name = [[NSString alloc] initWithUTF8String:class_getImageName(class)];
        if ([name rangeOfString:[[NSBundle mainBundle] bundlePath]].location == NSNotFound) { break; }

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
