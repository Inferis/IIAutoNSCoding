//
// ** File:     NSObject+PropertyDescription.h
// ** Location: ~/BGANTESharedLibrary/Categories/NSObject+PropertyDescription
//

#import <Foundation/Foundation.h>

@interface NSObject (PropertyDescription)

- (NSString *)propertyDescription;
- (NSString *)propertyDescriptionWithoutTypes;
- (uint)propertyHash;

@end
