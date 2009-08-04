// from: http://www.cocoadev.com/index.pl?BaseSixtyFour
// by MiloBird (http://www.cocoadev.com/index.pl?MiloBird)
// "It's public domain, just use it."
// 
#import <Cocoa/Cocoa.h>


@interface NSData (MBBase64)

+ (id)dataWithBase64EncodedString:(NSString *)string;     //  Padding '=' characters are optional. Whitespace is ignored.
- (NSString *)base64Encoding;

@end

