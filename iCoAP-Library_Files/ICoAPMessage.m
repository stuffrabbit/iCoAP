//
//  ICoAPMessage.m
//  iCoAP
//
//  Created by Wojtek Kordylewski on 18.06.13.

#import "ICoAPMessage.h"

@implementation ICoAPMessage


- (id)init {
    if (self = [super init]) {
        self.optionDict = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (id)initAsRequestConfirmable:(BOOL)con requestMethod:(uint)req sendToken:(BOOL)token payload:(NSString *)payload {
    if (self = [self init]) {
        if (con) {
            self.type = IC_CONFIRMABLE;
        }
        else {
            self.type = IC_NON_CONFIRMABLE;
        }
        if (req < 32) {
            self.code = req;
        }
        else {
            self.code = IC_GET;
        }
        
        self.isRequest = YES;
        self.isTokenRequested = token;
        self.payload = payload;
    }
    return self;
}

- (void)addOption:(uint)option withValue:(NSString *)value {
    NSMutableArray *valueArray;
    
    if ([self.optionDict valueForKey:[NSString stringWithFormat:@"%i", option]]) {
        valueArray = [self.optionDict valueForKey:[NSString stringWithFormat:@"%i", option]];
    }
    else {
        valueArray = [[NSMutableArray alloc] init];
        [self.optionDict setValue:valueArray forKey:[NSString stringWithFormat:@"%i", option]];
    }
    
    [valueArray addObject:value];
}

@end
