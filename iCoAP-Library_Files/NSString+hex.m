//
//  NSString+hex.m
//  iCoAP
//
//  Created by Wojtek Kordylewski on 15.06.13.

#import "NSString+hex.h"

@implementation NSString (hex)

+ (NSString *)hexStringFromString:(NSString *) string {
    return [self stringFromDataWithHex:[NSData dataWithBytes:[string cStringUsingEncoding:NSUTF8StringEncoding] length:strlen([string cStringUsingEncoding:NSUTF8StringEncoding])]];
}

+ (NSString *)stringFromHexString:(NSString *) string {
    NSMutableString *result = [[NSMutableString alloc] init];
    for (int i = 0; i < [string length] / 2; i++) {
        NSString * hexByte = [string substringWithRange: NSMakeRange(i * 2, 2)];
        int charResult = 0;
        sscanf([hexByte cStringUsingEncoding:NSUTF8StringEncoding], "%x", &charResult);
        [result appendFormat:@"%c", charResult];
    }
    return result;
}

+ (NSString *)stringFromDataWithHex:(NSData *)data{
	// We first need to get the length of our hexstring
	// data.length returns the length in bytes, so we *2 to get as hexstring
	NSUInteger capacity = data.length * 2;
	// Create a new NSMutableString with the correct lenght
	NSMutableString *mutableString = [NSMutableString stringWithCapacity:capacity];
	// get the bytes of data to be able to loop through it
	const unsigned char *buf = (const unsigned char*) [data bytes];
	 
	NSInteger t;
	for (t=0; t<data.length; ++t) {
		// "%02x" will append a 0 if the value is less than 2 digits (i.e. 4 becomes 04)
		[mutableString appendFormat:@"%02lx", (unsigned long)buf[t]];
	}
	return [NSString stringWithString:mutableString];
}

+ (NSString *)get0To4ByteHexStringFromInt:(int32_t)value {
    NSString *valueString;
    if (value == 0) {
        valueString = @"";
    }
    else if (value < 255) {
        valueString = [NSString stringWithFormat:@"%02X", value];
    }
    else if (value <= 65535) {
        valueString = [NSString stringWithFormat:@"%04X", value];
    }
    else if (value <= 16777215) {
        valueString = [NSString stringWithFormat:@"%06X", value];
    }
    else {
        valueString = [NSString stringWithFormat:@"%08X", value];
    }
    return valueString;    
}
@end
