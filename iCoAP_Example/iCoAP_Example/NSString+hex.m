//
//  NSString+hex.m
//  iCoAP
//
//  Created by Wojtek Kordylewski on 15.06.13.

#import "NSString+hex.h"

@implementation NSString (hex)

+ (NSString *)hexStringFromString:(NSString *) string {
    NSString *result = @"";
    for (int i = 0; i < [string length]; i++) {
        result = [NSString stringWithFormat:@"%@%02X", result, [string characterAtIndex:i]];
    }
    return result;
}

+ (NSString *)stringFromHexString:(NSString *) string {
    NSMutableString *result = [[NSMutableString alloc] init];
    for (int i = 0; i < [string length] / 2; i++) {
        NSString * hexByte = [string substringWithRange: NSMakeRange(i * 2, 2)];
        int charResult = 0;
        sscanf([hexByte cStringUsingEncoding:NSASCIIStringEncoding], "%x", &charResult);
        [result appendFormat:@"%c", charResult];
    }
    return result;
}

+ (NSString *)stringFromDataWithHex:(NSData *)data{
    NSString *result = [[data description] stringByReplacingOccurrencesOfString:@" " withString:@""];
    result = [result substringWithRange:NSMakeRange(1, [result length] - 2)];
    
    return result;
}

@end
