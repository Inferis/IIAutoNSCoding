//
//  TestModels.h
//  AutoNSCodingDemo
//
//  Created by Tom Adriaenssen on 27/05/15.
//  Copyright (c) 2015 Tom Adriaenssen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IIAutoNSCoding.h"

@interface SubModel : NSObject

@property (nonatomic, strong) NSNumber *aNumber;
@property (nonatomic, strong) NSValue *aValue;

@end

@interface TestModel : NSObject

@property (nonatomic, strong, readonly) NSString *suchReadOnly;
@property (nonatomic, strong) NSString *aString;
@property (nonatomic, strong) NSDate *aDate;
@property (nonatomic, strong, getter=getTheURL) NSURL *anURL;
@property (nonatomic, assign, setter=setTheBool:) BOOL aBool;
@property (nonatomic, assign) NSInteger anInteger;
@property (nonatomic, strong) SubModel *subModel;
@property (nonatomic, strong) NSArray *things;
@property (nonatomic, strong) NSDictionary *reference;

@end

@interface AnotherModel : NSObject

@property (nonatomic, strong) NSArray *yow;

@end

@interface ThirdModel : NSObject

@property (nonatomic, assign) NSUInteger blue;

@end
