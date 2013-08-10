//
//  iCoAPMessage.m
//  iCoAP
//
//  Created by Wojtek Kordylewski on 18.06.13.

#import "iCoAPMessage.h"

@implementation iCoAPMessage


- (id)init {
    self = [super init];
    if (self) {
        self.optionDict = [[NSMutableDictionary alloc] init];
        self.isFinal = YES;
    }
    return self;
}

- (id)initAsRequestConfirmable:(BOOL)con requestMethod:(uint)req sendToken:(BOOL)token payload:(NSString *)payload {
    self = [self init];
    if (self) {
        if (con) {
            self.type = CONFIRMABLE;
        }
        else {
            self.type = NON_CONFIRMABLE;
        }
        if (req < 32) {
            self.code = req;
        }
        else {
            self.code = GET;
        }
        
        self.isRequest = YES;
        self.isTokenRequested = token;
        self.payload = payload;
    }
    return self;
}

- (void)addOption:(uint)option withValue:(NSString *)value {
    NSMutableArray *valueArray;
    
    if ([self.optionDict valueForKey:[NSString stringWithFormat:@"%i", option]] == nil) {
        valueArray = [[NSMutableArray alloc] init];
        [self.optionDict setValue:valueArray forKey:[NSString stringWithFormat:@"%i", option]];
    }
    else {
        valueArray = [self.optionDict valueForKey:[NSString stringWithFormat:@"%i", option]];
    }
    [valueArray addObject:value];

}

@end
