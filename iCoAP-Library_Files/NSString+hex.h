//
//  NSString+hex.h
//  iCoAP
//
//  Created by Wojtek Kordylewski on 15.06.13.

/*
 *  This simple Category extends the NSString Class
 *  and provides three methods to manage string translations required
 *  for the iCoAP iOS library.
 */


#import <Foundation/Foundation.h>


@interface NSString (hex)

/*
 *  'hexStringFromString:':
 *  Encodes the given string to a UTF-8 hex-value representation of
 *  the given 'string'
 */
+ (NSString *)hexStringFromString:(NSString *) string;

/*
 *  'stringFromHexString:':
 *  Decodes the given UTF-8 hex-value 'string'
 */
+ (NSString *)stringFromHexString:(NSString *) string;

/*
 *  'stringFromDataWithHex:':
 *  Translates the given 'data', which contains a hex-value, to a string 
 *  with the same hex-value.
 */
+ (NSString *)stringFromDataWithHex:(NSData *) data;



+ (NSString *)get0To4ByteHexStringFromInt:(int32_t)value;
@end
