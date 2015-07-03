//
//  IIAutoNSCoding.h
//  AutoNSCodingDemo
//
//  Created by Tom Adriaenssen on 27/05/15.
//  Copyright (c) 2015 Tom Adriaenssen. All rights reserved.
//

#import <Foundation/Foundation.h>

#define AUTO_INJECT_CHILDREN @"AUTO_INJECT_CHILDREN"

#define II_AUTO_NSCODING(opts) \
+ (void)load { \
    [IIAutoNSCoding inject:self options:@#opts]; \
}




@interface IIAutoNSCoding : NSObject

+ (void)inject:(Class)class;
+ (void)inject:(Class)class options:(id)options;

@end
