//
//  TestModels.m
//  AutoNSCodingDemo
//
//  Created by Tom Adriaenssen on 27/05/15.
//  Copyright (c) 2015 Tom Adriaenssen. All rights reserved.
//

#import "TestModels.h"
#import "NSObject+PropertyDescription.h"

@implementation TestModel {
    NSTimeInterval _interval;
}

II_AUTO_NSCODING(AUTO_INJECT_CHILDREN)

- (NSString *)suchReadOnly
{
    return @"readonly";
}

- (void)setADate:(NSDate *)aDate
{
    _interval = [aDate timeIntervalSinceReferenceDate];
}

- (NSDate *)aDate
{
    return _interval == 0 ? nil : [NSDate dateWithTimeIntervalSinceReferenceDate:_interval];
}

- (NSString *)description
{
    return [self propertyDescription];
}

@end

@implementation SubModel

II_AUTO_NSCODING()

- (NSString *)description
{
    return [self propertyDescription];
}

@end

@implementation AnotherModel

II_AUTO_NSCODING()

- (NSString *)description
{
    return [self propertyDescription];
}

@end

@implementation ThirdModel

II_AUTO_NSCODING()

- (NSString *)description
{
    return [self propertyDescription];
}

@end
