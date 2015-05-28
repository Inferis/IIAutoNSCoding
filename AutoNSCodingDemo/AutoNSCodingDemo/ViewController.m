//
//  ViewController.m
//  AutoNSCodingDemo
//
//  Created by Tom Adriaenssen on 27/05/15.
//  Copyright (c) 2015 Tom Adriaenssen. All rights reserved.
//

#import "ViewController.h"
#import "TestModels.h"
#import "NSObject+PropertyDescription.h"

@interface ViewController ()

@property (nonatomic, strong) UIViewController *childController;

@end

@implementation ViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    
    TestModel *model = [TestModel new];
    model.aClass = [self class];
    model.aStruct = *(__bridge struct objc_object*)self;
    model.block = ^(NSArray *x) { return [NSObject new]; };
    model.aString = @"abc";
    model.aDate = [NSDate new];
    model.anURL = [NSURL URLWithString:@"http://www.test.be"];
    model.subModel = [SubModel new];
    model.subModel.select = @selector(viewDidAppear:);
    model.subModel.aNumber = @123;
    model.subModel.aValue = [NSValue valueWithCGAffineTransform:CGAffineTransformIdentity];
    model.things = @[[SubModel new], [AnotherModel new]];
    model.reference = @{ @"sm": [SubModel new], @"dm": [ThirdModel new] };
    
    NSLog(@"model = %@", [model propertyDescription]);
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:model];

    TestModel *model2 = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    NSLog(@"model2 = %@", [model2 propertyDescription]);
    
    NSLog(@"%ld vs %ld", [model hash], [model2 hash]);
    
    NSLog(@"equal: %@", [model isEqual:model2] ? @"YES" : @"NO");
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
