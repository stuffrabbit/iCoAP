//
//  iCoAPTransmission.m
//  iCoAP
//
//  Created by Wojtek Kordylewski on 25.06.13.


#import "iCoAPTransmission.h"
#import "NSString+hex.h"

@interface iCoAPTransmission ()
- (BOOL)setupUdpSocket;
- (void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data fromAddress:(NSData *)address withFilterContext:(id)filterContext;

- (void)noResponseExpected;
- (void)sendDidReceiveMessageToDelegateWithCoAPMessage:(iCoAPMessage *)coapMessage;
- (void)sendFailWithErrorToDelegateWithErrorCode:(iCoAPTransmissionErrorCode)error;

- (NSMutableData *)getHexDataFromString:(NSString *)string;

- (void)sendCircumstantialResponseWithMessageID:(uint)messageID token:(uint)token type:(Type)type toAddress:(NSData *)address;

- (void)startSending;
- (void)performTransmissionCycle;
- (void)sendCoAPMessage;

@end

@implementation iCoAPTransmission

#pragma mark - Init

- (id)initWithRegistrationAndSendRequestWithCoAPMessage:(iCoAPMessage *)cO toHost:(NSString* )host port:(uint)port delegate:(id)delegate {
    if (self = [super init]) {
        self.delegate = delegate;
        [self registerAndSendRequestWithCoAPMessage:cO toHost:host port:port];
    }
    return self;
}

- (BOOL)setupUdpSocket {
    self.udpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    
    NSError *error = nil;
    if (![self.udpSocket bindToPort:self.udpPort error:&error]) {
        return NO;
    }
    
    if (![self.udpSocket beginReceiving:&error]) {
        [self.udpSocket close];
        return NO;
    }
    return YES;
}

#pragma mark - Decode Message

- (iCoAPMessage *)decodeCoAPMessageFromData:(NSData *)data {
    NSString *hexString = [NSString stringFromDataWithHex:data];
    
    //Check if header exists:
    if ([hexString length] < 8) {
        return nil;
    }
    
    iCoAPMessage *cO = [[iCoAPMessage alloc] init];
    
    cO.isRequest = NO;
    
    //Check Version and type (first 4 bits)
    cO.type = strtol([[hexString substringWithRange:NSMakeRange(0, 1)] UTF8String], NULL, 16);
    if (CONFIRMABLE < cO.type > RESET) {
        cO = nil;
        return nil;
    }
    
    //Check Token length and save it.
    uint tokenLength = strtol([[hexString substringWithRange:NSMakeRange(1, 1)] UTF8String], NULL, 16); // in Bytes

    cO.token = strtol([[hexString substringWithRange:NSMakeRange(8, tokenLength * 2)] UTF8String], NULL, 16);
    
    //Code
    cO.code = strtol([[hexString substringWithRange:NSMakeRange(2, 2)] UTF8String], NULL, 16);
     
    //Message ID
    cO.messageID = strtol([[hexString substringWithRange:NSMakeRange(4, 4)] UTF8String], NULL, 16);
    
    //Options && Payload
    int optionIndex = 8 + (tokenLength * 2);
    int payloadStartIndex = optionIndex;
    uint prevOptionDelta = 0;
    
    
    //Check if Options and More exists
    BOOL isOptionLoopRunning = YES;
    
    while (isOptionLoopRunning) {
        if (optionIndex + 2 < [hexString length]) {
            uint optionDelta = strtol([[hexString substringWithRange:NSMakeRange(optionIndex, 1)] UTF8String], NULL, 16);
            uint optionLength = strtol([[hexString substringWithRange:NSMakeRange(optionIndex + 1, 1)] UTF8String], NULL, 16);
            
            if (optionDelta == kOptionDeltaPayloadIndicator) {
                //Payload should follow instead of Option_length. Verifying...
                if (optionLength != kOptionDeltaPayloadIndicator) {
                    cO = nil;
                    return nil;
                }
                isOptionLoopRunning = NO;
                payloadStartIndex = optionIndex;
                continue;
            }
            
            uint extendedDelta = 0;
            int optionIndexOffset = 2; //marks the range between the beginning of the initial option byte and the end of the 'option delta' plus 'option lenght' extended bytes in hex steps (2 = 1 byte)
            
            if (optionDelta == k8bitIntForOption) {
                optionIndexOffset += 2;
            }
            else if (optionDelta == k16bitIntForOption) {
                optionIndexOffset += 4;
            }
            
            if (optionIndex + optionIndexOffset <= [hexString length]) {
                extendedDelta = strtol([[hexString substringWithRange:NSMakeRange(optionIndex + 2, optionIndexOffset - 2)] UTF8String], NULL, 16);
            }
            else {
                cO = nil;
                return nil;
            }
            
            //Verify Length
            int optionLengthExtendedOffsetIndex = optionIndexOffset;
            if (optionLength == k8bitIntForOption) {
                optionIndexOffset += 2;
            }
            else if (optionLength == k16bitIntForOption) {
                optionIndexOffset += 4;
            }
            else if (optionLength == kOptionDeltaPayloadIndicator) {
                cO = nil;
                return nil;
            }
            optionLength += strtol([[hexString substringWithRange:NSMakeRange(optionIndex + optionLengthExtendedOffsetIndex , optionIndexOffset - optionLengthExtendedOffsetIndex)] UTF8String], NULL, 16);

            
            if (optionIndex + optionIndexOffset + optionLength * 2 > [hexString length]) {
                cO = nil;
                return nil;
            }
            
            NSString *optVal = [hexString substringWithRange:NSMakeRange(optionIndex + optionIndexOffset, optionLength * 2)];            
            
            [cO addOptionNumber:optionDelta + extendedDelta + prevOptionDelta withValue:optVal];
            
            prevOptionDelta += optionDelta + extendedDelta;
            optionIndex += optionIndexOffset + optionLength * 2;
        }
        else {
            isOptionLoopRunning = NO;
            payloadStartIndex = optionIndex;
        }
    }
    
    //Payload, first check if payloadmarker exists
    if (payloadStartIndex + 2 < [hexString length]) {
        cO.payload = [hexString substringFromIndex:payloadStartIndex + 2];
    }
    
    return cO;
}

#pragma mark - Encode Message

- (NSData *)encodeDataFromCoAPMessage:(iCoAPMessage *)cO {
    NSMutableString *final = [[NSMutableString alloc] init];
    NSString *tokenAsString;
    
    if (cO.token == 0) {
        tokenAsString = @"";
    }
    else if (cO.token > 255) {
        tokenAsString = [NSString stringWithFormat:@"%04X", cO.token];
    }
    else {
        tokenAsString = [NSString stringWithFormat:@"%02X", cO.token];
    }

    [final appendString: [NSString stringWithFormat:@"%01X%01X%02X%04X%@", cO.type, [tokenAsString length] / 2, cO.code, cO.messageID, tokenAsString]];
    
    NSArray *sortedArray;
    sortedArray = [[cO.optionDict allKeys] sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
        return [a integerValue] > [b integerValue];
    }];
    
    uint previousDelta = 0;
    for (NSString* key in sortedArray) {
        uint delta = [key intValue] - previousDelta;
        uint length;
        
        if ([key intValue] == BLOCK2 || [key intValue] == ETAG) {
            length = [[cO.optionDict valueForKey:key] length] / 2;
        }
        else {
            length = [[cO.optionDict valueForKey:key] length];
        }
        
        NSString *extendedDelta = @"";
        NSString *extendedLength = @"";
        
        if (delta >= 269) {
            [final appendString:[NSString stringWithFormat:@"%01X", 14]];
            extendedDelta = [NSString stringWithFormat:@"%04X", delta - 269];
        }
        else if (delta >= 13) {
            [final appendString:[NSString stringWithFormat:@"%01X", 13]];
            extendedDelta = [NSString stringWithFormat:@"%02X", delta - 13];
        }
        else {
            [final appendString:[NSString stringWithFormat:@"%01X", delta]];
        }
        
        if (length >= 269) {
            [final appendString:[NSString stringWithFormat:@"%01X", 14]];
            extendedLength = [NSString stringWithFormat:@"%04X", length - 269];
            //
        }
        else if (length >= 13) {
            [final appendString:[NSString stringWithFormat:@"%01X", 13]];
            extendedLength = [NSString stringWithFormat:@"%02X", length - 13];
        }
        else {
            [final appendString:[NSString stringWithFormat:@"%01X", length]];
        }
        
        [final appendString:extendedDelta];
        [final appendString:extendedLength];
        
        if ([key intValue] == BLOCK2 || [key intValue] == ETAG) {
            [final appendString:[cO.optionDict valueForKey:key]];
        }
        else {
            [final appendString:[NSString hexStringFromString:[cO.optionDict valueForKey:key]]];
        }
        
        previousDelta += delta;
    }    
    
    //Payload encoded to UTF-8
    if ([cO.payload length] > 0) {
        [final appendString:[NSString stringWithFormat:@"%02X%@", 255, [NSString hexStringFromString:cO.payload]]];
    }

    return [self getHexDataFromString:final];
}


#pragma mark - GCD Async UDP Socket Delegate

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data fromAddress:(NSData *)address withFilterContext:(id)filterContext {
    
    iCoAPMessage *cO = [self decodeCoAPMessageFromData:data];
    
    //Check if received data is a valid CoAP Message
    if (cO == nil) {
        return;
    }

    //Set Timestamp
    cO.timestamp = [NSDate date];
    
    //Check for spam and if Observe is Cancelled
    if ((cO.messageID != pendingCoAPMessageInTransmission.messageID && cO.token != pendingCoAPMessageInTransmission.token) || ([cO.optionDict valueForKey:[NSString stringWithFormat:@"%i", OBSERVE]] != nil && isObserveCancelled && cO.type != ACKNOWLEDGMENT)) {
        if (cO.type <= NON_CONFIRMABLE) {
            [self sendCircumstantialResponseWithMessageID:cO.messageID token:cO.token type:RESET toAddress:address];
        }
        return;
    }
    
    //Invalidate Timers: Resend- and Max-Wait Timer
    if (cO.type == ACKNOWLEDGMENT || cO.type == RESET || cO.type == NON_CONFIRMABLE) {
        [sendTimer invalidate];
        [maxWaitTimer invalidate];
    }

    if (cO.type == ACKNOWLEDGMENT && cO.code == 0) {
        cO.isFinal = NO;
    }
    
    //Separate Response / Observe: Send ACK
    if (cO.type == CONFIRMABLE) {        
        [self sendCircumstantialResponseWithMessageID:cO.messageID token:cO.token type:ACKNOWLEDGMENT toAddress:address];
    }
    
    //Block Options: Only send a Block2 request when observe option is inactive:
    if ([cO.optionDict valueForKey:[NSString stringWithFormat:@"%i", BLOCK2]] != nil && [cO.optionDict valueForKey:[NSString stringWithFormat:@"%i", OBSERVE]] == nil) {
        NSString *blockValue = [cO.optionDict valueForKey:[NSString stringWithFormat:@"%i", BLOCK2]];
        uint blockNum = strtol([[blockValue substringToIndex:[blockValue length] - 1] UTF8String], NULL, 16);
        uint blockTail = strtol([[blockValue substringFromIndex:[blockValue length] - 1] UTF8String], NULL, 16);
        
        if (blockTail > 7) {
            //More Flag is set
            iCoAPMessage *blockObject = [[iCoAPMessage alloc] init];
            blockObject.isRequest = YES;
            blockObject.type = CONFIRMABLE;
            blockObject.code = pendingCoAPMessageInTransmission.code;
            blockObject.messageID = pendingCoAPMessageInTransmission.messageID + 1;
            blockObject.token = pendingCoAPMessageInTransmission.token;
            blockObject.host = pendingCoAPMessageInTransmission.host;
            blockObject.port = pendingCoAPMessageInTransmission.port;

            NSString *newBlockValue;
            
            if (blockNum >= 4095 ) {
                newBlockValue = [NSString stringWithFormat:@"%05X%01X", blockNum + 1, blockTail - 8];
            }
            else if (blockNum >= 15) {
                newBlockValue = [NSString stringWithFormat:@"%03X%01X", blockNum + 1, blockTail - 8];
            }
            else {
                newBlockValue = [NSString stringWithFormat:@"%01X%01X", blockNum + 1, blockTail - 8];
            }
            
            [blockObject.optionDict setValue:newBlockValue forKey:[NSString stringWithFormat:@"%i", BLOCK2]];
            
            pendingCoAPMessageInTransmission = blockObject;
            [self startSending];
            cO.isFinal = NO;
        }
    }
    
    //Check for Observe Option: If Observe Option is present, the message is only sent to the delegate if the order is correct.
    if ([cO.optionDict valueForKey:[NSString stringWithFormat:@"%i", OBSERVE]] != nil && cO.type != ACKNOWLEDGMENT) {
        uint currentObserveValue = strtol([[cO.optionDict valueForKey:[NSString stringWithFormat:@"%i", OBSERVE]] UTF8String], NULL, 16);
        if (currentObserveValue > observeOptionValue) {
            observeOptionValue = currentObserveValue;
            [self sendDidReceiveMessageToDelegateWithCoAPMessage:cO];
        }
    }
    else {
        //No Observe Option: Sending object to delegate
        [self sendDidReceiveMessageToDelegateWithCoAPMessage:cO];
    }

}

#pragma mark - Delegate Method Calls

- (void)noResponseExpected {
    [self sendFailWithErrorToDelegateWithErrorCode:NO_RESPONSE_EXPECTED];
    [self closeTransmission];
}

- (void)sendDidReceiveMessageToDelegateWithCoAPMessage:(iCoAPMessage *)coapMessage {
    if ([self.delegate respondsToSelector:@selector(iCoAPTransmission:didReceiveCoAPMessage:)]) {
        [self.delegate iCoAPTransmission:self didReceiveCoAPMessage:coapMessage];
    }
}

- (void)sendFailWithErrorToDelegateWithErrorCode:(iCoAPTransmissionErrorCode)error {
    if ([self.delegate respondsToSelector:@selector(iCoAPTransmission:didFailWithErrorCode:)]) {
        [self.delegate iCoAPTransmission:self didFailWithErrorCode:error];
    }
}

#pragma mark - Other Methods

- (NSMutableData *)getHexDataFromString:(NSString *)string {
    NSMutableData *commandData= [[NSMutableData alloc] init];
    unsigned char byteRepresentation;
    char byte_chars[3] = {'\0','\0','\0'};
    
    for (int i = 0; i < (string.length / 2); i++) {
        byte_chars[0] = [string characterAtIndex:i * 2];
        byte_chars[1] = [string characterAtIndex:i * 2 + 1];
        byteRepresentation = strtol(byte_chars, NULL, 16);
        [commandData appendBytes:&byteRepresentation length:1];
    }

    return commandData;
}

- (void)cancelObserve {
    isObserveCancelled = YES;
}

#pragma mark - Send Methods

- (void)sendCircumstantialResponseWithMessageID:(uint)messageID token:(uint)token type:(Type)type toAddress:(NSData *)address {
    iCoAPMessage *ackObject = [[iCoAPMessage alloc] init];
    ackObject.isRequest = NO;
    ackObject.type = type;
    ackObject.messageID = messageID;
    
    NSData *send = [self encodeDataFromCoAPMessage:ackObject];
    [self.udpSocket sendData:send toAddress:address withTimeout:-1 tag:udpSocketTag];
    udpSocketTag++;
}

- (void)registerAndSendRequestWithCoAPMessage:(iCoAPMessage *)cO toHost:(NSString *)host port:(uint)port {
    cO.messageID = arc4random() % 65535;
    
    if ([cO isTokenRequested]) {
        cO.token = 1 + arc4random() % 65535;
    }
    
    cO.isRequest = YES;
    cO.host = host;
    cO.port = port;

    pendingCoAPMessageInTransmission = cO;
    
    if (self.udpSocket == nil) {
        if (![self setupUdpSocket]) {
            [self sendFailWithErrorToDelegateWithErrorCode:UDP_SOCKET_ERROR];
            return;
        }
    }
    
    [self startSending];
}

- (void)startSending {
    [sendTimer invalidate];
    [maxWaitTimer invalidate];
    isObserveCancelled = NO;
    observeOptionValue = 0;
    
    pendingCoAPMessageInTransmission.timestamp = [NSDate date];
    
    if (pendingCoAPMessageInTransmission.type == CONFIRMABLE) {
        retransmissionCounter = 0;
        maxWaitTimer = [NSTimer scheduledTimerWithTimeInterval:kMAX_TRANSMIT_WAIT target:self selector:@selector(noResponseExpected) userInfo:nil repeats:NO];
        
        [self performTransmissionCycle];
    }
    else {
        [self sendCoAPMessage];
    }
}

- (void)performTransmissionCycle {
    [self sendCoAPMessage];
    
    if (retransmissionCounter == kMAX_RETRANSMIT) {
        [self sendFailWithErrorToDelegateWithErrorCode:MAX_RETRANSMIT_REACHED];
    }
    else {
        double timeout = kACK_TIMEOUT * pow(2.0, retransmissionCounter) * kACK_RANDOM_FACTOR;
        sendTimer = [NSTimer scheduledTimerWithTimeInterval:timeout target:self selector:@selector(performTransmissionCycle) userInfo:nil repeats:NO];        
        retransmissionCounter++;
    }
}

- (void)sendCoAPMessage {
    NSData *send = [self encodeDataFromCoAPMessage:pendingCoAPMessageInTransmission];
    [self.udpSocket sendData:send toHost:pendingCoAPMessageInTransmission.host port:pendingCoAPMessageInTransmission.port withTimeout:-1 tag:udpSocketTag];
    udpSocketTag++;
}

- (void)closeTransmission {
    [self.udpSocket close];
    self.udpSocket = nil;
    [sendTimer invalidate];
    [maxWaitTimer invalidate];
    pendingCoAPMessageInTransmission = nil;
}

@end
