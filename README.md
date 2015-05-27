# IIAutoNSCoding

A contraption to make objects conform to NSSecureCoding without all the boilerplate code. Your objects become serializable *and* you don't have to write a bucketload of tedious and hard to maintain encoding/decoding code.

This is not meant to generally replace NSCoding code in all your objects, but more for simple data model objects which are not too complex.

Adding this to your models makes them serialize all properties (where possible).

It changes the actual class at runtime to conform to `NSSecureCoding`.

It will not try to override existing implementations of `NSCoding`, and it will only modify classes of libraries in your app bundle.

**Warning** This is a bit of experimental.

## Example

Suppose you have these models:

```objc
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
```

As you can see, they don't conform to `NSCoding`.

Adding `II_AUTO_NSCODING()` in their implementation:

```objc
@implementation TestModel

II_AUTO_NSCODING()

@end

@implementation SubModel

II_AUTO_NSCODING()

@end
```

makes sure they do. It automatically serializes all properties it can.

You can even have it do it recursively for every "non-compliant" class it encounters during encoding:

```objc
II_AUTO_NSCODING(AUTO_INJECT_CHILDREN)
```

But that's even more experimental. 😉

## Todo

1. Write a slew of tests
2. Turn this into a CocoaPod

No necessarily in that order.

## License

This code is licensed under the [MIT License](LICENSE).
